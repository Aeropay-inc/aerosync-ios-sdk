import XCTest
@testable import aerosync_ios_sdk

final class AerosyncSuccessPayloadTests: XCTestCase {
    private let single = """
    {"type":"pageSuccess","payload":{"connectionId":"conn-1","clientName":"Aeropay","aeroPassUserUuid":"uuid-1"%@}}
    """
    private let multi = """
    {"type":"pageSuccess","payload":{"accounts":[{"connectionId":"conn-1","accountType":"checking","accountNumberDisplay":"••••1234"},{"connectionId":"conn-2","accountType":"savings","accountNumberDisplay":"••••5678"}],"clientName":"Aeropay","aeroPassUserUuid":"uuid-1"%@}}
    """

    private func json(_ template: String, extra: String = "") -> String {
        String(format: template, extra)
    }

    func testSingleAccountWithoutMatchIndicatorStillParses() throws {
        guard case .singleAccount(let payload) = AerosyncSuccessPayload.parse(from: json(single)) else {
            return XCTFail("expected singleAccount")
        }
        XCTAssertEqual(payload.connectionId, "conn-1")
        XCTAssertEqual(payload.clientName, "Aeropay")
        XCTAssertEqual(payload.aeroPassUserUuid, "uuid-1")
        XCTAssertNil(payload.matchIndicator)
    }

    func testSingleAccountWithEachKnownMatchIndicator() {
        let cases: [(String, AerosyncMatchIndicator)] = [
            ("MATCH", .match), ("REVIEW", .review), ("NOT_APPLICABLE", .notApplicable),
        ]
        for (raw, expected) in cases {
            let result = AerosyncSuccessPayload.parse(from: json(single, extra: ",\"matchIndicator\":\"\(raw)\""))
            guard case .singleAccount(let payload) = result else {
                return XCTFail("expected singleAccount for \(raw)")
            }
            XCTAssertEqual(payload.matchIndicator, expected)
            XCTAssertEqual(result?.matchIndicator, expected)
            XCTAssertEqual(expected.rawValue, raw)
        }
    }

    func testMultiAccountWithoutMatchIndicatorStillParses() {
        guard case .multiAccount(let payload) = AerosyncSuccessPayload.parse(from: json(multi)) else {
            return XCTFail("expected multiAccount")
        }
        XCTAssertEqual(payload.accounts.count, 2)
        XCTAssertNil(payload.matchIndicator)
    }

    func testMultiAccountWithTopLevelMatchIndicator() {
        let result = AerosyncSuccessPayload.parse(from: json(multi, extra: ",\"matchIndicator\":\"REVIEW\""))
        guard case .multiAccount(let payload) = result else {
            return XCTFail("expected multiAccount")
        }
        XCTAssertEqual(payload.matchIndicator, .review)
        XCTAssertEqual(result?.matchIndicator, .review)
    }

    func testUnknownMatchIndicatorDoesNotBreakParsing() {
        let result = AerosyncSuccessPayload.parse(from: json(single, extra: ",\"matchIndicator\":\"SOMETHING_NEW\""))
        XCTAssertEqual(result?.matchIndicator, .unknown("SOMETHING_NEW"))
        XCTAssertEqual(result?.matchIndicator?.rawValue, "SOMETHING_NEW")
    }

    func testNonStringMatchIndicatorDoesNotBreakParsing() {
        let result = AerosyncSuccessPayload.parse(from: json(multi, extra: ",\"matchIndicator\":42"))
        guard case .multiAccount = result else {
            return XCTFail("expected multiAccount")
        }
        XCTAssertEqual(result?.matchIndicator, .unknown(""))
    }

    func testNullMatchIndicatorIsNil() {
        let result = AerosyncSuccessPayload.parse(from: json(single, extra: ",\"matchIndicator\":null"))
        XCTAssertNotNil(result)
        XCTAssertNil(result?.matchIndicator)
    }

    func testUnwrappedPayloadWithMatchIndicator() {
        let bare = #"{"connectionId":"conn-1","clientName":"Aeropay","aeroPassUserUuid":"uuid-1","matchIndicator":"MATCH"}"#
        XCTAssertEqual(AerosyncSuccessPayload.parse(from: bare)?.matchIndicator, .match)
    }

    func testInvalidJsonReturnsNil() {
        XCTAssertNil(AerosyncSuccessPayload.parse(from: "not json"))
    }
}

final class AerosyncWidgetErrorTests: XCTestCase {
    private let nameMismatch = #"{"type":"widgetError","payload":"Type: NAME_MISMATCH | Code: AC-166 | Message: For your security, you can only link a bank account that is in your name."}"#

    func testNameMismatchEnvelopeFromWebView() throws {
        let error = try XCTUnwrap(AerosyncWidgetError.parse(from: nameMismatch))
        XCTAssertEqual(error.type, "NAME_MISMATCH")
        XCTAssertEqual(error.code, "AC-166")
        XCTAssertEqual(error.message, "For your security, you can only link a bank account that is in your name.")
        XCTAssertTrue(error.isNameMismatch)
        XCTAssertTrue(error.raw.hasPrefix("Type: NAME_MISMATCH"))
    }

    func testBareErrorString() throws {
        let error = try XCTUnwrap(AerosyncWidgetError.parse(from: "Type: SERVER_ERROR | Code: AC-100 | Message: Something went wrong"))
        XCTAssertEqual(error.type, "SERVER_ERROR")
        XCTAssertEqual(error.code, "AC-100")
        XCTAssertEqual(error.message, "Something went wrong")
        XCTAssertFalse(error.isNameMismatch)
    }

    func testDictionaryBody() throws {
        let body: [String: Any] = ["type": "widgetError", "payload": "Type: NAME_MISMATCH | Code: AC-166 | Message: x"]
        XCTAssertTrue(try XCTUnwrap(AerosyncWidgetError.parse(from: body)).isNameMismatch)
    }

    func testCodeAloneMarksNameMismatch() throws {
        let error = try XCTUnwrap(AerosyncWidgetError.parse(from: "Code: AC-166 | Message: x"))
        XCTAssertNil(error.type)
        XCTAssertTrue(error.isNameMismatch)
    }

    func testMessageContainingSeparatorIsKeptWhole() throws {
        let error = try XCTUnwrap(AerosyncWidgetError.parse(from: "Type: SERVER_ERROR | Code: AC-1 | Message: a | b"))
        XCTAssertEqual(error.message, "a | b")
    }

    func testGenericErrorWithoutTypeOrCode() throws {
        let error = try XCTUnwrap(AerosyncWidgetError.parse(from: #"{"type":"widgetError","payload":"Error | Message: boom"}"#))
        XCTAssertNil(error.type)
        XCTAssertNil(error.code)
        XCTAssertEqual(error.message, "boom")
        XCTAssertEqual(error.raw, "Error | Message: boom")
    }

    func testUnparseableBodiesReturnNil() {
        XCTAssertNil(AerosyncWidgetError.parse(from: 42))
        XCTAssertNil(AerosyncWidgetError.parse(from: ""))
        XCTAssertNil(AerosyncWidgetError.parse(from: ["payload": 1]))
    }
}
