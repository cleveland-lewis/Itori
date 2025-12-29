import CoreData
import Foundation
import Combine

final class PersistenceController {
    static let shared = PersistenceController()

    private let cloudKitContainerIdentifier = "iCloud.com.cwlewisiii.Roots"
    var container: NSPersistentCloudKitContainer
    private var cancellables = Set<AnyCancellable>()

    var viewContext: NSManagedObjectContext { container.viewContext }
    
    private(set) var isCloudKitEnabled = false

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Roots")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Missing persistent store description")
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        let iCloudSyncEnabled = AppSettingsModel.shared.enableICloudSync
        isCloudKitEnabled = iCloudSyncEnabled
        
        if iCloudSyncEnabled {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: cloudKitContainerIdentifier
            )
        } else {
            description.cloudKitContainerOptions = nil
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            LOG_DATA(.error, "Persistence", "Persistent store load failed: \(error.localizedDescription)")
            
            // If CloudKit failed, recreate container without CloudKit
            if iCloudSyncEnabled {
                LOG_DATA(.info, "Persistence", "Retrying without CloudKit - creating new container.")
                isCloudKitEnabled = false
                
                // Create new container without CloudKit
                let newContainer = NSPersistentCloudKitContainer(name: "Roots")
                guard let newDescription = newContainer.persistentStoreDescriptions.first else {
                    fatalError("Missing persistent store description on retry")
                }
                
                newDescription.cloudKitContainerOptions = nil
                newDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                newDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                
                var retryError: Error?
                newContainer.loadPersistentStores { _, error in
                    retryError = error
                }
                
                if retryError == nil {
                    // Success - use new container
                    container = newContainer
                    loadError = nil
                } else {
                    loadError = retryError
                    LOG_DATA(.error, "Persistence", "Retry without CloudKit failed: \(retryError!.localizedDescription)")
                }
            }
        }

        // Final fallback: in-memory store
        if let error = loadError {
            LOG_DATA(.error, "Persistence", "Using in-memory store as final fallback.")
            isCloudKitEnabled = false
            
            let memoryContainer = NSPersistentCloudKitContainer(name: "Roots")
            guard let memoryDescription = memoryContainer.persistentStoreDescriptions.first else {
                fatalError("Missing persistent store description for memory store")
            }
            
            memoryDescription.url = URL(fileURLWithPath: "/dev/null")
            memoryDescription.cloudKitContainerOptions = nil
            
            memoryContainer.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("In-memory store load failed: \(error.localizedDescription)")
                }
            }
            
            container = memoryContainer
        }

        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        
        observeCloudKitToggle()
    }
    
    private func observeCloudKitToggle() {
        NotificationCenter.default.publisher(for: .iCloudSyncSettingChanged)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let enabled = notification.object as? Bool {
                    self.updateCloudKitSync(enabled: enabled)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateCloudKitSync(enabled: Bool) {
        guard enabled != isCloudKitEnabled else { return }
        
        LOG_DATA(.info, "Persistence", "iCloud sync toggled to: \(enabled)")
        isCloudKitEnabled = enabled
        
        if enabled {
            // Enable CloudKit sync by reinitializing the store with CloudKit options
            enableCloudKitSync()
        } else {
            // Disable CloudKit sync - data remains local
            LOG_DATA(.info, "Persistence", "iCloud sync disabled. Data will remain local-only.")
        }
    }
    
    private func enableCloudKitSync() {
        guard let description = container.persistentStoreDescriptions.first,
              let storeURL = description.url else {
            LOG_DATA(.error, "Persistence", "Cannot enable CloudKit: missing store description")
            return
        }
        
        do {
            // Save any pending changes
            if viewContext.hasChanges {
                try viewContext.save()
            }
            
            // Remove the existing store
            if let store = container.persistentStoreCoordinator.persistentStore(for: storeURL) {
                try container.persistentStoreCoordinator.remove(store)
            }
            
            // Configure CloudKit options
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: cloudKitContainerIdentifier
            )
            
            // Re-add the store with CloudKit enabled
            try container.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: nil
            )
            
            LOG_DATA(.info, "Persistence", "iCloud sync enabled successfully")
        } catch {
            LOG_DATA(.error, "Persistence", "Failed to enable iCloud sync: \(error.localizedDescription)")
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func saveViewContext() {
        save(context: viewContext)
    }

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        touchTimestamps(in: context)
        do {
            try context.save()
        } catch {
            LOG_DATA(.error, "Persistence", "Failed to save context: \(error.localizedDescription)")
        }
    }

    private func touchTimestamps(in context: NSManagedObjectContext) {
        let now = Date()
        for object in context.insertedObjects {
            if object.value(forKey: "createdAt") == nil {
                object.setValue(now, forKey: "createdAt")
            }
            object.setValue(now, forKey: "updatedAt")
        }
        for object in context.updatedObjects {
            object.setValue(now, forKey: "updatedAt")
        }
    }
}

extension Notification.Name {
    static let iCloudSyncSettingChanged = Notification.Name("iCloudSyncSettingChanged")
}
