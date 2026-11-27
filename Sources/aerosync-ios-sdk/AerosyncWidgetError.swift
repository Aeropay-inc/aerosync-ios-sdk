import Foundation

/// Typed view of the value delivered to ``AerosyncSDK``'s `onError` closure.
///
/// The widget sends errors as a JSON string,
/// `{ "type": "widgetError", "payload": "Type: <type> | Code: <code> | Message: <message>" }`.
/// This helper unwraps the envelope and splits the payload string into its
/// parts. Some errors omit parts (for example `Code: <code> | Message: <message>`
/// or `Error | Message: <message>`), so every field is optional.
///
/// `onError` itself keeps its existing `(Any) -> Void` signature — this is an
/// opt-in parsing helper, so adopting it is non-breaking.
///
/// Usage:
/// ```swift
/// onError: { body in
///     guard let error = AerosyncWidgetError.parse(from: body) else { return }
///     if error.isNameMismatch {
///         // The bank account owner isn't the user. No account was linked.
///     }
/// }
/// ```
public struct AerosyncWidgetError: Equatable {
    /// Error type sent by the widget for a bank-owner name mismatch.
    public static let nameMismatchType = "NAME_MISMATCH"
    /// AeroSync error code for a bank-owner name mismatch.
    public static let nameMismatchCode = "AC-166"

    /// Error category, e.g. `"NAME_MISMATCH"` or `"SERVER_ERROR"`.
    public let type: String?
    /// AeroSync error code, e.g. `"AC-166"`.
    public let code: String?
    /// Human-readable message (the widget's own copy for mapped codes).
    public let message: String?
    /// The full error string, after unwrapping the JSON envelope.
    public let raw: String

    /// `true` when the user tried to link a bank account whose owner isn't
    /// the user. No `connectionId` is returned and `onSuccess` isn't called.
    public var isNameMismatch: Bool {
        type == Self.nameMismatchType || code == Self.nameMismatchCode
    }

    public init(type: String?, code: String?, message: String?, raw: String) {
        self.type = type
        self.code = code
        self.message = message
        self.raw = raw
    }

    /// Parses the value delivered to `onError`. Accepts the raw
    /// `{ "type": "widgetError", "payload": "..." }` JSON string, a
    /// dictionary with a string `payload`, or the bare
    /// `Type: … | Code: … | Message: …` string. Returns `nil` only when no
    /// error string can be found.
    public static func parse(from body: Any) -> AerosyncWidgetError? {
        guard let errorString = extractErrorString(from: body),
              !errorString.isEmpty else {
            return nil
        }
        return parse(errorString: errorString)
    }

    private static func extractErrorString(from body: Any) -> String? {
        if let dictionary = body as? [String: Any] {
            return dictionary["payload"] as? String
        }
        guard let string = body as? String else {
            return nil
        }
        if let data = string.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return (json["payload"] as? String) ?? string
        }
        return string
    }

    private static func parse(errorString: String) -> AerosyncWidgetError {
        var type: String?
        var code: String?
        var message: String?

        let segments = errorString.components(separatedBy: " | ")
        for (index, segment) in segments.enumerated() {
            if let value = value(of: segment, key: "Type") {
                type = value
            } else if let value = value(of: segment, key: "Code") {
                code = value
            } else if segment.hasPrefix("Message:") {
                // The message is last and may itself contain " | ".
                let rest = segments[index...].joined(separator: " | ")
                message = rest.dropFirst("Message:".count).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return AerosyncWidgetError(type: type, code: code, message: message, raw: errorString)
    }

    private static func value(of segment: String, key: String) -> String? {
        let prefix = key + ":"
        guard segment.hasPrefix(prefix) else { return nil }
        return segment.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
    }
}
