import Foundation
import CryptoKit

extension Data {
    /// Computes SHA256 hash of data
    func sha256Hash() -> String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
