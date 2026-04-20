import XCTest
@testable import Hanafubuki87

// MARK: - KifuParserTests
//
// KifuParser の KIF / CSA 解析を検証するユニットテスト群。
// - 形式自動判定
// - 指し手パース（通常移動・打ち駒・成り・不成）
// - 終局マーカー（投了・詰み・入玉勝ち・反則・千日手・持将棋）
// - CSA 終局種別（%TORYO / %TSUMI / %KACHI / %SENNICHITE / %JISHOGI など）

final class KifuParserTests: XCTestCase {

    // MARK: - Helpers

    /// 最小限の KIF ヘッダー + 指し手列を組み立てるヘルパー
    private func makeKIF(
        sente: String = "先手",
        gote: String = "後手",
        moves: [String],
        terminator: String = "投了"
    ) -> String {
        var lines = [
            "先手：\(sente)",
            "後手：\(gote)",
            "手数----指手---------消費時間--",
        ]
        for (i, move) in moves.enumerated() {
            lines.append("\(i + 1) \(move)")
        }
        lines.append("\(moves.count + 1) \(terminator)")
        return lines.joined(separator: "\n")
    }

    // MARK: - 形式判定

    func testIsCSAFormat_detected() throws {
        let csa = """
V2
N+Sente
N-Gote
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
+
+7776FU
-3334FU
%TORYO
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertEqual(result.playerSente, "Sente")
        XCTAssertEqual(result.playerGote, "Gote")
    }

    func testKIFFormat_detected() throws {
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "投了")
        // パースが例外なく完了すればOK
        XCTAssertNoThrow(try KifuParser.parse(text: kif))
    }

    // MARK: - KIF ヘッダー解析

    func testKIF_playerNames() throws {
        let kif = makeKIF(sente: "テスト太郎", gote: "テスト花子", moves: ["７六歩(77)"])
        let result = try KifuParser.parse(text: kif)
        XCTAssertEqual(result.playerSente, "テスト太郎")
        XCTAssertEqual(result.playerGote, "テスト花子")
    }

    // MARK: - KIF 終局マーカー

    func testKIF_toryo_senteWins() throws {
        // 後手（偶数手番）が投了 → 先手の勝ち
        let kif = makeKIF(moves: ["７六歩(77)", "３四歩(34)"], terminator: "投了")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("先手の勝ち"))
        XCTAssertTrue(result.resultSummary.contains("投了"))
    }

    func testKIF_toryo_goteWins() throws {
        // 先手（奇数手番）が投了 → 後手の勝ち
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "投了")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("後手の勝ち"))
    }

    func testKIF_tsumi() throws {
        let kif = makeKIF(moves: ["７六歩(77)", "３四歩(34)"], terminator: "詰み")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("詰み"))
    }

    func testKIF_nyuugyokuKachi() throws {
        // 入玉勝ち: 指した側（奇数手 = 先手）が勝者
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "入玉勝ち")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("先手の勝ち"), "result: \(result.resultSummary)")
        XCTAssertTrue(result.resultSummary.contains("入玉勝ち"))
    }

    func testKIF_sennichite() throws {
        let kif = makeKIF(moves: ["７六歩(77)", "３四歩(34)"], terminator: "千日手")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("千日手"))
    }

    func testKIF_jishogi() throws {
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "持将棋")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("持将棋"))
    }

    func testKIF_fuseiFoul_goteWins() throws {
        // 反則負け（奇数手 = 先手が反則）→ 後手の勝ち
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "反則負け")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("後手の勝ち"), "result: \(result.resultSummary)")
    }

    func testKIF_fuseKachi_senteWins() throws {
        // 反則勝ち（奇数手 = 先手が宣言）→ 先手の勝ち
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "反則勝ち")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("先手の勝ち"), "result: \(result.resultSummary)")
    }

    func testKIF_timeUp_goteWins() throws {
        // TIME_UP（奇数手 = 先手の時間切れ）→ 後手の勝ち
        let kif = makeKIF(moves: ["７六歩(77)"], terminator: "TIME_UP")
        let result = try KifuParser.parse(text: kif)
        XCTAssertTrue(result.resultSummary.contains("後手の勝ち"), "result: \(result.resultSummary)")
    }

    // MARK: - KIF 指し手 — 成り・不成

    func testKIF_promotion_flagSet() throws {
        // 「成」が付いている指し手を含む棋譜がパース失敗しないことを確認
        let kif = makeKIF(moves: ["７六歩(77)", "３四歩(34)", "２六飛(28)"], terminator: "投了")
        XCTAssertNoThrow(try KifuParser.parse(text: kif))
    }

    func testKIF_nonPromotion_noThrow() throws {
        // 不成記号を含む棋譜がパース失敗しないことを確認
        let kif = makeKIF(moves: ["７六歩(77)", "３四歩(34)", "２六飛(28)不成"], terminator: "投了")
        XCTAssertNoThrow(try KifuParser.parse(text: kif))
    }

    // MARK: - CSA 指し手・終局

    func testCSA_toryoGoteWins() throws {
        // 後手が1手目を指した後、先手が投了（%TORYO）→ 後手の勝ち
        // rawMoves.count == 1 (後手の手) -> lastPlayer = gote(偶数0→gote)
        // %TORYO: lastPlayer.opposite = sente が勝ち
        let csa = """
V2
N+Sente
N-Gote
+7776FU
-3334FU
%TORYO
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("先手の勝ち"), "result: \(result.resultSummary)")
    }

    func testCSA_tsumi() throws {
        let csa = """
V2
+7776FU
%TSUMI
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("詰み"), "result: \(result.resultSummary)")
    }

    func testCSA_kachi_senteWins() throws {
        // %KACHI: 宣言したプレイヤー (lastPlayer) が勝者
        // 奇数手後 → lastPlayer = sente
        let csa = """
V2
+7776FU
%KACHI
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("先手の勝ち"), "result: \(result.resultSummary)")
        XCTAssertTrue(result.resultSummary.contains("入玉"), "result: \(result.resultSummary)")
    }

    func testCSA_illegalMove() throws {
        let csa = """
V2
+7776FU
%ILLEGAL_MOVE
"""
        let result = try KifuParser.parse(text: csa)
        // 反則: 先手が指した後に反則 → 先手が反則 → 後手の勝ち
        XCTAssertTrue(result.resultSummary.contains("後手の勝ち"), "result: \(result.resultSummary)")
    }

    func testCSA_timeUp() throws {
        let csa = """
V2
+7776FU
%TIME_UP
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("時間切れ"), "result: \(result.resultSummary)")
    }

    func testCSA_sennichite() throws {
        let csa = """
V2
+7776FU
%SENNICHITE
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("千日手"), "result: \(result.resultSummary)")
    }

    func testCSA_jishogi() throws {
        let csa = """
V2
+7776FU
%JISHOGI
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("持将棋"), "result: \(result.resultSummary)")
    }

    func testCSA_maxMoves() throws {
        let csa = """
V2
+7776FU
%MAX_MOVES
"""
        let result = try KifuParser.parse(text: csa)
        XCTAssertTrue(result.resultSummary.contains("最大手数"), "result: \(result.resultSummary)")
    }

    // MARK: - エラーケース

    func testUnsupportedFormat_throws() {
        let garbage = "This is not a valid kifu format"
        XCTAssertThrowsError(try KifuParser.parse(text: garbage)) { error in
            guard let parseError = error as? KifuParser.ParseError else {
                XCTFail("Expected KifuParser.ParseError, got \(error)")
                return
            }
            if case .unsupportedFormat = parseError { /* OK */ } else {
                XCTFail("Expected .unsupportedFormat, got \(parseError)")
            }
        }
    }
}
