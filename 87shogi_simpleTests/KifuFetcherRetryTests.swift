import XCTest
@testable import Hanafubuki87

// MARK: - KifuFetcherRetryTests
//
// KifuFetcher のリトライ / オフライン検知 / バックオフ設定を検証するテスト群。
// 実際のネットワーク通信を必要とするテスト（integration tests）と、
// エラーの分類ロジックを確認する単体テストを含む。

final class KifuFetcherRetryTests: XCTestCase {

    // MARK: - KifuFetchError: ローカライズ文字列

    func testError_invalidURL_description() {
        let error = KifuFetchError.invalidURL
        XCTAssertEqual(error.errorDescription, "URLが不正です")
    }

    func testError_httpError_description() {
        let error = KifuFetchError.httpError(404)
        XCTAssertTrue(error.errorDescription?.contains("404") == true)
    }

    func testError_noData_description() {
        let error = KifuFetchError.noData
        XCTAssertNotNil(error.errorDescription)
    }

    func testError_decodingFailed_description() {
        let error = KifuFetchError.decodingFailed
        XCTAssertNotNil(error.errorDescription)
    }

    func testError_networkUnavailable_description() {
        let error = KifuFetchError.networkUnavailable
        XCTAssertEqual(error.errorDescription, "ネットワークに接続できません")
    }

    func testError_maxRetriesExceeded_description() {
        let underlying = KifuFetchError.noData
        let error = KifuFetchError.maxRetriesExceeded(underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("再試行") == true)
    }

    // MARK: - 不正URL は即座にエラー（リトライなし）

    func testFetchText_invalidURL_throwsImmediately() async {
        do {
            _ = try await KifuFetcher.fetchText(from: "not a url")
            XCTFail("Expected error")
        } catch let error as KifuFetchError {
            if case .invalidURL = error { /* OK */ } else {
                XCTFail("Expected .invalidURL, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchText_emptyString_throwsInvalidURL() async {
        do {
            _ = try await KifuFetcher.fetchText(from: "")
            XCTFail("Expected error")
        } catch let error as KifuFetchError {
            if case .invalidURL = error { /* OK */ } else {
                XCTFail("Expected .invalidURL, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - 定数確認

    func testDefaultMaxRetries_isReasonable() {
        XCTAssertGreaterThanOrEqual(KifuFetcher.defaultMaxRetries, 1)
        XCTAssertLessThanOrEqual(KifuFetcher.defaultMaxRetries, 5)
    }

    func testRetryBaseDelay_isPositive() {
        XCTAssertGreaterThan(KifuFetcher.retryBaseDelay, 0)
    }

    // MARK: - KifuImporter.userFacingMessage

    func testUserFacingMessage_networkUnavailable() {
        let fetchError = KifuFetchError.networkUnavailable
        let importError = KifuImporter.ImportError.fetchFailed(fetchError)
        let message = KifuImporter.userFacingMessage(for: importError)
        XCTAssertTrue(message.contains("ネットワーク") || message.contains("オフライン"),
                      "Expected network error message, got: \(message)")
    }

    func testUserFacingMessage_maxRetriesExceeded() {
        let fetchError = KifuFetchError.maxRetriesExceeded(underlying: KifuFetchError.noData)
        let importError = KifuImporter.ImportError.fetchFailed(fetchError)
        let message = KifuImporter.userFacingMessage(for: importError)
        XCTAssertTrue(message.contains("再試行"),
                      "Expected retry message, got: \(message)")
    }

    func testUserFacingMessage_httpError() {
        let fetchError = KifuFetchError.httpError(503)
        let importError = KifuImporter.ImportError.fetchFailed(fetchError)
        let message = KifuImporter.userFacingMessage(for: importError)
        XCTAssertTrue(message.contains("503"),
                      "Expected HTTP 503 in message, got: \(message)")
    }

    func testUserFacingMessage_parseFailed() {
        let parseError = KifuParser.ParseError.unsupportedFormat
        let importError = KifuImporter.ImportError.parseFailed(parseError)
        let message = KifuImporter.userFacingMessage(for: importError)
        XCTAssertFalse(message.isEmpty)
    }
}
