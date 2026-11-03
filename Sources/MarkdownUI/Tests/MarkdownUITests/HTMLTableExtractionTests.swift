import XCTest

@testable import SendbirdMarkdownUI

/// `BlockNode.extractTableData(from:)` — turns an HTML `<table>` block into the rows that
/// `TableView` / `CompatTableView` draw. Contract: every row has at least `alignments.count`
/// cells, because both views read `cells[column]` for every column. Column count stays the
/// header width (at least 1). Rows short of it are padded with empty cells; rows longer than it
/// and the column count itself are left as before, so only inputs that used to crash change.
final class HTMLTableExtractionTests: XCTestCase {

  private func table(_ html: String) -> (columns: Int, rows: [[String]]) {
    let data = BlockNode.htmlBlock(content: html).extractTableData(from: html)
    let rows = data.rows.map { row in
      row.cells.map { cell in
        cell.content.map { inline -> String in
          guard case .text(let text) = inline else { return "?" }
          return text
        }.joined()
      }
    }
    return (data.alignments.count, rows)
  }

  // MARK: - Rows that used to crash are padded

  func testShortBodyRowIsPadded() {
    let result = table("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td>C</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 2)
    XCTAssertEqual(result.rows, [["A", "B"], ["C", ""]])
  }

  func testEmptyBodyRowIsPadded() {
    let result = table("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr></tr></tbody></table>")
    XCTAssertEqual(result.columns, 2)
    XCTAssertEqual(result.rows, [["A", "B"], ["", ""]])
  }

  func testColspanRowIsPadded() {
    let result = table("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td colspan=\"2\">C</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 2)
    XCTAssertEqual(result.rows, [["A", "B"], ["C", ""]])
  }

  func testEmptyRowWithoutHeaderIsPadded() {
    let result = table("<table><tbody><tr><td>A</td></tr><tr></tr></tbody></table>")
    XCTAssertEqual(result.columns, 1)
    XCTAssertEqual(result.rows, [["A"], [""]])
  }

  func testEmptyHeaderRowIsPadded() {
    let result = table("<table><thead><tr></tr></thead><tbody><tr><td>A</td><td>B</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 1)
    XCTAssertEqual(result.rows, [[""], ["A", "B"]])
  }

  func testTableOfEmptyRowsIsPadded() {
    let result = table("<table><thead><tr></tr></thead><tbody><tr></tr></tbody></table>")
    XCTAssertEqual(result.columns, 1)
    XCTAssertEqual(result.rows, [[""], [""]])
  }

  // MARK: - Tables that rendered before are unchanged

  func testRectangularTableIsUnchanged() {
    let result = table("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td>C</td><td>D</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 2)
    XCTAssertEqual(result.rows, [["A", "B"], ["C", "D"]])
  }

  func testLongBodyRowIsKept() {
    let result = table("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td>C</td><td>D</td><td>E</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 2)
    XCTAssertEqual(result.rows, [["A", "B"], ["C", "D", "E"]])
  }

  func testMissingHeaderKeepsSingleColumn() {
    let result = table("<table><tbody><tr><td>A</td></tr><tr><td>B</td><td>C</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 1)
    XCTAssertEqual(result.rows, [["A"], ["B", "C"]])
  }

  func testEmptyTagsAreKeptAsCells() {
    let result = table("<table><thead><tr><th>A</th><th></th></tr></thead><tbody><tr><td></td><td>D</td></tr></tbody></table>")
    XCTAssertEqual(result.columns, 2)
    XCTAssertEqual(result.rows, [["A", ""], ["", "D"]])
  }

  func testTableWithoutRowsIsEmpty() {
    let result = table("<table></table>")
    XCTAssertEqual(result.columns, 1)
    XCTAssertEqual(result.rows, [])
  }

  // MARK: - Pipe tables (cmark) stay rectangular

  func testPipeTableRowsMatchColumnCount() {
    let blocks = MarkdownContent("| A | B |\n|---|---|\n| C |\n| D | E | F |").blocks
    guard case .table(let alignments, let rows) = blocks.first else {
      return XCTFail("expected a table, got \(blocks)")
    }
    XCTAssertEqual(alignments.count, 2)
    XCTAssertEqual(rows.map(\.cells.count), [2, 2, 2])
  }
}
