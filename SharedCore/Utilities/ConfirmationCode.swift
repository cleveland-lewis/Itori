import Foundation
import Security

enum ConfirmationCode {
    private static let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")

    static func generate() -> String {
        let groupSize = 4
        let groups = 2
        let totalCount = groupSize * groups
        var result: [Character] = []
        result.reserveCapacity(totalCount)

        var randomBytes = [UInt8](repeating: 0, count: totalCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, totalCount, &randomBytes)
        if status != errSecSuccess {
            return fallbackCode(groupSize: groupSize, groups: groups)
        }

        for byte in randomBytes {
            let index = Int(byte) % alphabet.count
            result.append(alphabet[index])
        }

        return stride(from: 0, to: totalCount, by: groupSize)
            .map { String(result[$0..<$0 + groupSize]) }
            .joined(separator: "-")
    }

    private static func fallbackCode(groupSize: Int, groups: Int) -> String {
        let totalCount = groupSize * groups
        let chars = (0..<totalCount).compactMap { _ in alphabet.randomElement() }
        return stride(from: 0, to: totalCount, by: groupSize)
            .map { String(chars[$0..<$0 + groupSize]) }
            .joined(separator: "-")
    }
}
