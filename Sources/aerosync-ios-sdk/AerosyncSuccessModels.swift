import Foundation

/// One linked account within a ``AerosyncMultiAccountSuccessPayload``.
public struct AerosyncLinkedAccount: Decodable {
    public let connectionId: String
    public let accountType: String
    public let accountNumberDisplay: String
}

/// Result of the bank-owner name check, sent in `onSuccess` when the
/// merchant has name matching enabled.
///
/// Values:
/// - ``match``: the bank account owner's name matches the user.
/// - ``review``: a partial match (for example a nickname or only the last
///   name). The link went through; you may want to review it.
/// - ``notApplicable``: the names couldn't be compared (for example a
///   business account, or no owner name from the bank). The link went through.
/// - ``unknown(_:)``: a value this SDK version doesn't know yet. New values
///   never make parsing fail.
///
/// A mismatch is never a success: the widget shows a mismatch screen and
/// `onError` receives `NAME_MISMATCH` / `AC-166` instead.
public enum AerosyncMatchIndicator: Equatable, Hashable, Decodable {
    case match
    case review
    case notApplicable
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "MATCH": self = .match
        case "REVIEW": self = .review
        case "NOT_APPLICABLE": self = .notApplicable
        default: self = .unknown(rawValue)
        }
    }

    /// The value as sent by the widget, e.g. `"MATCH"`.
    public var rawValue: String {
        switch self {
        case .match: return "MATCH"
        case .review: return "REVIEW"
        case .notApplicable: return "NOT_APPLICABLE"
        case .unknown(let value): return value
        }
    }

    /// Never throws: a non-string value decodes as `.unknown("")`, so an
    /// unexpected `matchIndicator` can't make the whole payload fail to parse.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: (try? container.decode(String.self)) ?? "")
    }
}

/// Single-account success payload (default / AeroPass returning user).
public struct AerosyncSingleAccountSuccessPayload: Decodable {
    public let connectionId: String
    public let clientName: String
    public let aeroPassUserUuid: String
    /// Name-check result. `nil` when the check didn't run: name matching is
    /// off for the merchant, a reconnect, or a returning AeroPass user who
    /// picked a saved bank.
    public let matchIndicator: AerosyncMatchIndicator?
}

/// Multi-account success payload — returned instead of
/// ``AerosyncSingleAccountSuccessPayload`` when the merchant's AeroSync
/// configuration has multi-account linking enabled.
public struct AerosyncMultiAccountSuccessPayload: Decodable {
    public let accounts: [AerosyncLinkedAccount]
    public let clientName: String
    public let aeroPassUserUuid: String
    /// Name-check result for the whole link (one value next to `accounts`,
    /// never per account). `nil` when the check didn't run.
    public let matchIndicator: AerosyncMatchIndicator?
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

    /// Name-check result, from either payload shape. `nil` when the check
    /// didn't run.
    public var matchIndicator: AerosyncMatchIndicator? {
        switch self {
        case .singleAccount(let payload): return payload.matchIndicator
        case .multiAccount(let payload): return payload.matchIndicator
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
