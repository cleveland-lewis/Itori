import CoreData
import Foundation

/// Repository for managing planner analyses and AI results with iCloud sync
final class PlannerAnalysisRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    convenience init() {
        self.init(persistenceController: .shared)
    }

    // MARK: - Create Analysis

    /// Save a planner analysis result
    func saveAnalysis(
        type: String,
        startDate: Date,
        endDate: Date,
        analysisData: [String: Any],
        resultData: [String: Any]?
    ) async throws -> UUID {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            let mo = PlannerAnalysisMO(context: context)
            let id = UUID()
            let now = Date()

            mo.id = id
            mo.analysisType = type
            mo.startDate = startDate
            mo.endDate = endDate
            mo.createdAt = now
            mo.updatedAt = now

            // Serialize analysis data to JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: analysisData),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                mo.analysisJSON = jsonString
            }

            // Serialize result data to JSON if available
            if let resultData,
               let jsonData = try? JSONSerialization.data(withJSONObject: resultData),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                mo.resultJSON = jsonString
            }

            try context.save()
            return id
        }
    }

    // MARK: - Fetch Analyses

    /// Fetch analyses for a date range
    func fetchAnalyses(
        startDate: Date,
        endDate: Date,
        type: String? = nil
    ) async throws -> [PlannerAnalysisResult] {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            let request = PlannerAnalysisMO.fetchRequest()

            var predicates: [NSPredicate] = [
                NSPredicate(format: "startDate >= %@ AND endDate <= %@", startDate as CVarArg, endDate as CVarArg)
            ]

            if let type {
                predicates.append(NSPredicate(format: "analysisType == %@", type))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let results = try context.fetch(request)
            return results.compactMap { self.toDomain($0) }
        }
    }

    /// Fetch most recent analysis of a type
    func fetchLatestAnalysis(type: String) async throws -> PlannerAnalysisResult? {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            let request = PlannerAnalysisMO.fetchRequest()
            request.predicate = NSPredicate(format: "analysisType == %@", type)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 1

            guard let result = try context.fetch(request).first else {
                return nil
            }

            return self.toDomain(result)
        }
    }

    // MARK: - Update Analysis

    /// Update analysis with new result data
    func updateAnalysis(
        id: UUID,
        resultData: [String: Any]
    ) async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request = PlannerAnalysisMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            guard let mo = try context.fetch(request).first else {
                throw NSError(
                    domain: "PlannerAnalysisRepository",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Analysis not found"]
                )
            }

            if let jsonData = try? JSONSerialization.data(withJSONObject: resultData),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                mo.resultJSON = jsonString
            }

            mo.updatedAt = Date()
            try context.save()
        }
    }

    // MARK: - Delete Analysis

    /// Delete old analyses (cleanup)
    func deleteOldAnalyses(olderThan date: Date) async throws -> Int {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            let request = PlannerAnalysisMO.fetchRequest()
            request.predicate = NSPredicate(format: "createdAt < %@", date as CVarArg)

            let results = try context.fetch(request)
            let count = results.count

            for mo in results {
                context.delete(mo)
            }

            try context.save()
            return count
        }
    }

    /// Delete specific analysis
    func deleteAnalysis(id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request = PlannerAnalysisMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            guard let mo = try context.fetch(request).first else {
                throw NSError(
                    domain: "PlannerAnalysisRepository",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Analysis not found"]
                )
            }

            context.delete(mo)
            try context.save()
        }
    }

    // MARK: - Private Helpers

    private func toDomain(_ mo: PlannerAnalysisMO) -> PlannerAnalysisResult? {
        guard let id = mo.id,
              let analysisType = mo.analysisType,
              let startDate = mo.startDate,
              let endDate = mo.endDate,
              let createdAt = mo.createdAt,
              let updatedAt = mo.updatedAt
        else {
            return nil
        }

        var analysisData: [String: Any] = [:]
        if let jsonString = mo.analysisJSON,
           let jsonData = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        {
            analysisData = dict
        }

        var resultData: [String: Any]?
        if let jsonString = mo.resultJSON,
           let jsonData = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        {
            resultData = dict
        }

        return PlannerAnalysisResult(
            id: id,
            analysisType: analysisType,
            startDate: startDate,
            endDate: endDate,
            analysisData: analysisData,
            resultData: resultData,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Domain Model

public struct PlannerAnalysisResult: Identifiable {
    public let id: UUID
    public let analysisType: String
    public let startDate: Date
    public let endDate: Date
    public let analysisData: [String: Any]
    public let resultData: [String: Any]?
    public let createdAt: Date
    public let updatedAt: Date
}
