import CoreData
import Foundation
import Combine

final class PersistenceController {
    static let shared = PersistenceController()

    private let cloudKitContainerIdentifier = "iCloud.com.cwlewisiii.Itori"
    var container: NSPersistentCloudKitContainer
    private var cancellables = Set<AnyCancellable>()

    var viewContext: NSManagedObjectContext { container.viewContext }
    
    private(set) var isCloudKitEnabled = false
    private(set) var lastCloudKitStatusMessage: String? = nil

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Itori")

        var description = container.persistentStoreDescriptions.first
        if description == nil {
            LOG_DATA(.error, "Persistence", "CRITICAL: Missing persistent store description - using default")
            let fallbackDescription = NSPersistentStoreDescription()
            fallbackDescription.type = NSSQLiteStoreType
            container.persistentStoreDescriptions = [fallbackDescription]
            description = container.persistentStoreDescriptions.first
            if description == nil {
                LOG_DATA(.error, "Persistence", "CRITICAL: Could not create fallback description")
                let memoryDescription = NSPersistentStoreDescription()
                memoryDescription.url = URL(fileURLWithPath: "/dev/null")
                memoryDescription.type = NSInMemoryStoreType
                container.persistentStoreDescriptions = [memoryDescription]
                description = container.persistentStoreDescriptions.first
            }
        }
        
        guard let description else { return }

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
        
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            LOG_DATA(.error, "Persistence", "Persistent store load failed: \(error.localizedDescription)")
            print("[Persistence] Full error: \(error)")
            
            // If CloudKit failed, recreate container without CloudKit
            if iCloudSyncEnabled {
                LOG_DATA(.info, "Persistence", "Retrying without CloudKit - creating new container.")
                isCloudKitEnabled = false
                
                // Create new container without CloudKit
                let newContainer = NSPersistentCloudKitContainer(name: "Itori")
                guard let newDescription = newContainer.persistentStoreDescriptions.first else {
                    LOG_DATA(.error, "Persistence", "CRITICAL: Missing description on retry - using fallback")
                    // Use in-memory as last resort
                    let fallbackDesc = NSPersistentStoreDescription()
                    fallbackDesc.url = URL(fileURLWithPath: "/dev/null")
                    fallbackDesc.type = NSInMemoryStoreType
                    newContainer.persistentStoreDescriptions = [fallbackDesc]
                    var finalError: Error?
                    newContainer.loadPersistentStores { _, error in
                        finalError = error
                    }
                    if finalError != nil {
                        LOG_DATA(.error, "Persistence", "CRITICAL: In-memory store also failed")
                    }
                    container = newContainer
                    return
                }
                
                newDescription.cloudKitContainerOptions = nil
                newDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                newDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
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
            
            let memoryContainer = NSPersistentCloudKitContainer(name: "Itori")
            guard let memoryDescription = memoryContainer.persistentStoreDescriptions.first else {
                LOG_DATA(.error, "Persistence", "CRITICAL: Cannot create memory store description")
                // Absolute last resort - create minimal container
                let minimalDesc = NSPersistentStoreDescription()
                minimalDesc.url = URL(fileURLWithPath: "/dev/null")
                minimalDesc.type = NSInMemoryStoreType
                memoryContainer.persistentStoreDescriptions = [minimalDesc]
                var minimalError: Error?
                memoryContainer.loadPersistentStores { _, error in
                    minimalError = error
                }
                if let err = minimalError {
                    LOG_DATA(.error, "Persistence", "CRITICAL: Minimal store failed: \(err.localizedDescription)")
                }
                container = memoryContainer
                viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                viewContext.automaticallyMergesChangesFromParent = true
                observeCloudKitToggle()
                notifyCloudKitStatus(reason: initialCloudKitReason())
                return
            }
            
            memoryDescription.url = URL(fileURLWithPath: "/dev/null")
            memoryDescription.cloudKitContainerOptions = nil
            memoryDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            memoryDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            memoryContainer.loadPersistentStores { _, error in
                if let error = error {
                    LOG_DATA(.error, "Persistence", "CRITICAL: In-memory store load failed: \(error.localizedDescription)")
                    // Continue anyway - app will be degraded but won't crash
                }
            }
            
            container = memoryContainer
        }

        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        
        observeCloudKitToggle()
        notifyCloudKitStatus(reason: initialCloudKitReason())
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
        
        if enabled {
            // Enable CloudKit sync by reinitializing the store with CloudKit options
            enableCloudKitSync()
        } else {
            // Disable CloudKit sync - data remains local
            isCloudKitEnabled = false
            LOG_DATA(.info, "Persistence", "iCloud sync disabled. Data will remain local-only.")
            notifyCloudKitStatus(reason: "Disabled by user")
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
                options: description.options
            )
            
            LOG_DATA(.info, "Persistence", "iCloud sync enabled successfully")
            isCloudKitEnabled = true
            notifyCloudKitStatus(reason: "Connected")
        } catch {
            LOG_DATA(.error, "Persistence", "Failed to enable iCloud sync: \(error.localizedDescription)")
            isCloudKitEnabled = false
            let settings = AppSettingsModel.shared
            settings.enableICloudSync = false
            settings.save()
            notifyCloudKitStatus(reason: error.localizedDescription)
        }
    }

    private func notifyCloudKitStatus(reason: String?) {
        let friendly = friendlyCloudKitReason(reason: reason)
        lastCloudKitStatusMessage = friendly
        if AppSettingsModel.shared.devModeEnabled && AppSettingsModel.shared.devModeDataLogging {
            LOG_DATA(.info, "Persistence", "iCloud sync status: \(isCloudKitEnabled) - \(friendly)")
        }
        NotificationCenter.default.post(
            name: .iCloudSyncStatusChanged,
            object: isCloudKitEnabled,
            userInfo: ["reason": friendly]
        )
    }

    private func initialCloudKitReason() -> String? {
        if isCloudKitEnabled {
            return "Connected"
        }
        if AppSettingsModel.shared.enableICloudSync {
            return "Connecting…"
        }
        return "Disabled by user"
    }

    private func friendlyCloudKitReason(reason: String?) -> String {
        if isCloudKitEnabled {
            return "Connected to iCloud."
        }
        if !AppSettingsModel.shared.enableICloudSync {
            return "Sync is off. Your data stays on this Mac."
        }

        let lowered = reason?.lowercased() ?? ""
        if lowered.contains("not authenticated") || lowered.contains("not logged") || lowered.contains("account") {
            return "Sign in to iCloud in System Settings to enable sync."
        }
        if lowered.contains("permission") || lowered.contains("denied") {
            return "iCloud access is blocked. Check System Settings permissions."
        }
        if lowered.contains("network") || lowered.contains("offline") || lowered.contains("connection") {
            return "No network connection. iCloud sync will retry automatically."
        }
        if lowered.contains("icloud") || lowered.contains("cloudkit") {
            return "iCloud sync isn’t available right now. Please try again later."
        }
        if lowered.isEmpty || lowered == "connected" {
            return "iCloud sync isn’t available right now."
        }
        return "iCloud sync error: \(reason ?? "Unknown issue")."
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

    func resetPersistentStore() {
        guard let description = container.persistentStoreDescriptions.first,
              let storeURL = description.url else {
            LOG_DATA(.error, "Persistence", "Reset failed: missing store URL")
            return
        }

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }

            let coordinator = container.persistentStoreCoordinator
            for store in coordinator.persistentStores {
                try coordinator.remove(store)
            }

            try coordinator.destroyPersistentStore(
                at: storeURL,
                ofType: NSSQLiteStoreType,
                options: description.options
            )

            let iCloudEnabled = AppSettingsModel.shared.enableICloudSync
            if iCloudEnabled {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: cloudKitContainerIdentifier
                )
            } else {
                description.cloudKitContainerOptions = nil
            }

            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: description.options
            )

            viewContext.reset()
            viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            viewContext.automaticallyMergesChangesFromParent = true

            isCloudKitEnabled = iCloudEnabled
            notifyCloudKitStatus(reason: iCloudEnabled ? "Connected" : "Disabled by user")
        } catch {
            LOG_DATA(.error, "Persistence", "Reset failed: \(error.localizedDescription)")
        }
    }

    private func touchTimestamps(in context: NSManagedObjectContext) {
        let now = Date()
        for object in context.insertedObjects {
            // Only set timestamps if the entity has these attributes
            if let _ = object.entity.attributesByName["createdAt"] {
                // Check if createdAt is nil before setting
                if object.value(forKey: "createdAt") == nil {
                    object.setValue(now, forKey: "createdAt")
                }
            }
            if let _ = object.entity.attributesByName["updatedAt"] {
                object.setValue(now, forKey: "updatedAt")
            }
        }
        for object in context.updatedObjects {
            if let _ = object.entity.attributesByName["updatedAt"] {
                object.setValue(now, forKey: "updatedAt")
            }
        }
    }
}

extension Notification.Name {
    static let iCloudSyncSettingChanged = Notification.Name("iCloudSyncSettingChanged")
    static let iCloudSyncStatusChanged = Notification.Name("iCloudSyncStatusChanged")
}
