import Foundation

/// Configuration for Bring-Your-Own AI provider
struct BYOProviderConfig: Codable, Hashable {
    var apiKey: String
    var endpoint: String
    var model: String

    static var `default`: BYOProviderConfig {
        BYOProviderConfig(apiKey: "", endpoint: "", model: "")
    }
}
