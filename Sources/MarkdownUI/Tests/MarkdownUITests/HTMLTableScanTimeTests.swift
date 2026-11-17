import XCTest

@testable import SendbirdMarkdownUI

/// HTML tables whose `<thead>` is never closed.
///
/// `extractTableData` found the header with `<thead[^>]*>.*?<tr[^>]*>(.*?)</tr>.*?</thead>`.
/// Without `</thead>`, every `<tr>` after every `<thead>` scans to the end of the string before
/// failing, so the time grows with the square of the table size. The table is parsed while
/// SwiftUI builds the message body on the main thread.
final class HTMLTableScanTimeTests: XCTestCase {

  /// Generous upper bound. A table this size takes a few milliseconds with a single pass.
  private let limit: TimeInterval = 0.5

  private func tableData(_ html: String) -> (alignments: [RawTableColumnAlignment], rows: [RawTableRow]) {
    BlockNode.htmlBlock(content: html).extractTableData(from: html)
  }

  private func texts(_ row: RawTableRow) -> [String] {
    row.cells.map { $0.content.renderPlainText() }
  }

  private func timed<T>(_ work: () -> T) -> (T, TimeInterval) {
    let start = Date()
    let value = work()
    return (value, Date().timeIntervalSince(start))
  }

  private func rows(_ count: Int) -> String {
    (0..<count).map { "<tr><td>r\($0)</td><td>v</td></tr>" }.joined()
  }

  func testHeaderWithoutClosingTheadFinishesQuickly() {
    let html = "<table><thead>" + rows(600) + "</table>"
    let (data, elapsed) = timed { tableData(html) }
    XCTAssertLessThan(elapsed, limit, "unclosed <thead> with 600 rows took \(elapsed)s")
    // No </thead>, so there is no header row, the same as before.
    XCTAssertEqual(data.rows.count, 0)
  }

  func testRepeatedTheadWithoutClosingFinishesQuickly() {
    let html = "<table>" + String(repeating: "<thead>", count: 20) + rows(300) + "</table>"
    let (_, elapsed) = timed { tableData(html) }
    XCTAssertLessThan(elapsed, limit, "20 unclosed <thead> with 300 rows took \(elapsed)s")
  }

  func testClosedFirstHeaderRowFollowedByUnclosedRowsFinishesQuickly() {
    let unclosed = String(repeating: "<tr><th>x</th>", count: 5_000)
    let html = "<table><thead><tr><th>A</th></tr>" + unclosed + "</thead><tbody><tr><td>1</td></tr></tbody></table>"
    let (data, elapsed) = timed { tableData(html) }
    XCTAssertLessThan(elapsed, limit, "closed first row + 5,000 unclosed rows took \(elapsed)s")
    XCTAssertEqual(data.rows.first.map(texts), ["A"])
  }

  // MARK: - Unchanged results

  func testWellFormedTableKeepsHeaderAndRows() {
    let html = """
      <table><THEAD class="h"><tr><th>A</th><th>B</th></tr></THEAD>
      <tbody><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></tbody></table>
      """
    let data = tableData(html)
    XCTAssertEqual(data.alignments.count, 2)
    XCTAssertEqual(data.rows.map(texts), [["A", "B"], ["1", "2"], ["3", "4"]])
  }

  func testHeaderUsesTheFirstRowInsideThead() {
    let html = """
      <table><thead><tr><th>A</th></tr><tr><th>ignored</th></tr></thead>
      <tbody><tr><td>1</td></tr></tbody></table>
      """
    XCTAssertEqual(tableData(html).rows.map(texts), [["A"], ["1"]])
  }

  func testTableWithoutTheadHasOnlyBodyRows() {
    let html = "<table><tbody><tr><td>1</td><td>2</td></tr></tbody></table>"
    let data = tableData(html)
    XCTAssertEqual(data.alignments.count, 1)
    XCTAssertEqual(data.rows.map(texts), [["1"]])
  }

  func testClosingTheadInsideAnAttributeKeepsTheHeader() {
    let html = """
      <table><thead><tr data-note="</thead>"><th>A</th><th>B</th></tr></thead>
      <tbody><tr><td>1</td><td>2</td></tr></tbody></table>
      """
    XCTAssertEqual(tableData(html).rows.map(texts), [["A", "B"], ["1", "2"]])
  }

  func testClosingTheadInsideACommentKeepsTheHeader() {
    let html = "<table><thead><!-- </thead> --><tr><th>A</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table>"
    XCTAssertEqual(tableData(html).rows.map(texts), [["A"], ["1"]])
  }

  func testMalformedTheadNestingKeepsTheSameHeader() {
    for inner in [
      "<thead></thead><thead><tr><th>A</th></tr></thead>",
      "<thead><thead></thead><tr><th>A</th></tr></thead>",
      "<thead><tr><th>A</th></thead></tr></thead>",
    ] {
      XCTAssertEqual(tableData("<table>" + inner + "</table>").rows.first.map(texts), ["A"], inner)
    }
  }
}
