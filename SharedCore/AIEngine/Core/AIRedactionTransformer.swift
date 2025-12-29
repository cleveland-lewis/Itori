import Foundation

enum AIRedactionTransformer {
    static func redactJSONStrings(_ input: Data, using redactor: AIRedactor) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: input, options: [])
        let redacted = redactValue(object, using: redactor)
        return try JSONSerialization.data(withJSONObject: redacted, options: [])
    }

    private static func redactValue(_ value: Any, using redactor: AIRedactor) -> Any {
        switch value {
        case let string as String:
            return redactor.redact(string).redactedText
        case let array as [Any]:
            return array.map { redactValue($0, using: redactor) }
        case let dict as [String: Any]:
            var mapped: [String: Any] = [:]
            for (key, val) in dict {
                mapped[key] = redactValue(val, using: redactor)
            }
            return mapped
        default:
            return value
        }
    }
}
