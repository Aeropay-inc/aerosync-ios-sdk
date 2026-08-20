import Foundation

/// One linked account within a ``AerosyncMultiAccountSuccessPayload``.
public struct AerosyncLinkedAccount: Decodable {
    public let connectionId: String
    public let accountType: String
    public let accountNumberDisplay: String
}

/// Single-account success payload (default / AeroPass returning user).
public struct AerosyncSingleAccountSuccessPayload: Decodable {
    public let connectionId: String
    public let clientName: String
    public let aeroPassUserUuid: String
}

/// Multi-account success payload — returned instead of
/// ``AerosyncSingleAccountSuccessPayload`` when the merchant's AeroSync
/// configuration has multi-account linking enabled.
public struct AerosyncMultiAccountSuccessPayload: Decodable {
    public let accounts: [AerosyncLinkedAccount]
    public let clientName: String
    public let aeroPassUserUuid: String
}

/// Typed result for the JSON string delivered to ``AerosyncSDK``'s `onSuccess`
/// closure. The AeroSync hosted widget returns either a single connected
/// account (the default) or, when the merchant's configuration has
/// multi-account linking enabled, a list of linked accounts in the same
/// success event.
///
/// `onSuccess` itself keeps its existing `(String) -> Void` signature — this
/// is an opt-in parsing helper, so adopting it is non-breaking.
///
/// Usage:
/// ```swift
/// onSuccess: { message in
///     if let result = AerosyncSuccessPayload.parse(from: message) {
///         switch result {
///         case .multiAccount(let payload):
///             for account in payload.accounts { ... }
///         case .singleAccount(let payload):
///             print(payload.connectionId)
///         }
///     }
/// }
/// ```
public enum AerosyncSuccessPayload {
    case singleAccount(AerosyncSingleAccountSuccessPayload)
    case multiAccount(AerosyncMultiAccountSuccessPayload)

    public var clientName: String {
        switch self {
        case .singleAccount(let payload): return payload.clientName
        case .multiAccount(let payload): return payload.clientName
        }
    }

    public var aeroPassUserUuid: String {
        switch self {
        case .singleAccount(let payload): return payload.aeroPassUserUuid
        case .multiAccount(let payload): return payload.aeroPassUserUuid
        }
    }

    /// Parses the JSON string delivered to `onSuccess`. Accepts either the
    /// raw `{ "type": "pageSuccess", "payload": {...} }` envelope or an
    /// already-unwrapped payload object — a top-level `payload` object is
    /// unwrapped automatically if present. Presence of an `accounts` array
    /// on the (possibly unwrapped) data selects
    /// ``AerosyncMultiAccountSuccessPayload``; otherwise
    /// ``AerosyncSingleAccountSuccessPayload`` is returned. Returns `nil` if
    /// the string isn't valid JSON or doesn't match either shape.
    public static func parse(from jsonString: String) -> AerosyncSuccessPayload? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let payloadDict = (json["payload"] as? [String: Any]) ?? json
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict) else {
            return nil
        }

        let decoder = JSONDecoder()
        if payloadDict["accounts"] is [Any] {
            guard let multi = try? decoder.decode(AerosyncMultiAccountSuccessPayload.self, from: payloadData) else {
                return nil
            }
            return .multiAccount(multi)
        }
        guard let single = try? decoder.decode(AerosyncSingleAccountSuccessPayload.self, from: payloadData) else {
            return nil
        }
        return .singleAccount(single)
    }
}
