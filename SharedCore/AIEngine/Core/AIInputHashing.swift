import Foundation

enum AIInputHasher {
    static let defaultExcludedKeys: Set<String> = [
        "requestID",
        "timestamp",
        "currentTime",
        "now",
        "generatedAt",
        "computedAt",
        "uiState",
        "viewID",
        "viewId"
    ]

    static func hash(
        inputJSON: Data,
        excludedKeys: Set<String> = [],
        unorderedArrayKeys: Set<String> = []
    ) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: inputJSON, options: []) else {
            return inputJSON.sha256Hash()
        }

        let mergedExcluded = defaultExcludedKeys.union(excludedKeys)
        let canonical = canonicalize(
            object,
            excludedKeys: mergedExcluded,
            unorderedArrayKeys: unorderedArrayKeys
        )

        guard JSONSerialization.isValidJSONObject(canonical),
              let data = try? JSONSerialization.data(withJSONObject: canonical, options: [.sortedKeys])
        else {
            return inputJSON.sha256Hash()
        }

        return data.sha256Hash()
    }

    private static func canonicalize(
        _ value: Any,
        excludedKeys: Set<String>,
        unorderedArrayKeys: Set<String>
    ) -> Any {
        switch value {
        case let dict as [String: Any]:
            var normalized: [String: Any] = [:]
            for (key, rawValue) in dict where !excludedKeys.contains(key) {
                let cleanValue = canonicalize(
                    rawValue,
                    excludedKeys: excludedKeys,
                    unorderedArrayKeys: unorderedArrayKeys
                )
                normalized[key] = cleanValue
            }

            for key in unorderedArrayKeys {
                if let array = normalized[key] as? [Any] {
                    normalized[key] = sortUnorderedArray(
                        array,
                        excludedKeys: excludedKeys,
                        unorderedArrayKeys: unorderedArrayKeys
                    )
                }
            }

            return normalized
        case let array as [Any]:
            return array.map {
                canonicalize($0, excludedKeys: excludedKeys, unorderedArrayKeys: unorderedArrayKeys)
            }
        default:
            return value
        }
    }

    private static func sortUnorderedArray(
        _ array: [Any],
        excludedKeys: Set<String>,
        unorderedArrayKeys: Set<String>
    ) -> [Any] {
        let normalized = array.map {
            canonicalize($0, excludedKeys: excludedKeys, unorderedArrayKeys: unorderedArrayKeys)
        }

        return normalized.sorted { lhs, rhs in
            canonicalJSONString(lhs) < canonicalJSONString(rhs)
        }
    }

    private static func canonicalJSONString(_ value: Any) -> String {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8)
        else {
            return String(describing: value)
        }
        return string
    }
}
