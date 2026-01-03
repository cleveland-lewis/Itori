//
//  BaseRepository.swift
//  Roots
//
//  Base repository for Core Data operations with consistent error handling
//

import Foundation
import CoreData

/// Base protocol for all repositories
protocol Repository {
    associatedtype Entity: NSManagedObject
    var persistence: PersistenceController { get }
}

extension Repository {
    /// Fetch entity by ID
    func fetch(id: UUID, in context: NSManagedObjectContext) throws -> Entity? {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try context.fetch(request)
        return results.first as? Entity
    }
    
    /// Fetch all entities
    func fetchAll(in context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) throws -> [Entity] {
        let request = Entity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        let results = try context.fetch(request)
        return results as? [Entity] ?? []
    }
    
    /// Delete entity by ID
    func delete(id: UUID, in context: NSManagedObjectContext) throws {
        guard let entity = try fetch(id: id, in: context) else {
            throw RepositoryError.entityNotFound
        }
        context.delete(entity)
    }
    
    /// Save context with error handling
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            LOG_DATA(.error, "Repository", "Save failed: \(error.localizedDescription)")
            throw RepositoryError.saveFailed(error)
        }
    }
}

enum RepositoryError: LocalizedError {
    case entityNotFound
    case saveFailed(Error)
    case invalidData
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "Entity not found"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data provided"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        }
    }
}
