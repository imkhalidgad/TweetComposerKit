import Foundation

public struct TwitterCredentials: Sendable {
    public let clientID: String
    public let clientSecret: String
    public let redirectURI: String

    public init(clientID: String, clientSecret: String, redirectURI: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }
}
