import SwiftUI
import XCTest

@testable import SendbirdMarkdownUI

/// HTML tables whose rows do not all have as many cells as the header.
///
/// `TableView` (iOS 16+) and `CompatTableView` (iOS 14/15) both loop over the column
/// count and read `rows[row].cells[column]`, so a short row used to trap with an index
/// out of range. Pipe tables never take this path: cmark pads and trims their rows.
@available(iOS 16.0, *)
@MainActor
final class HTMLTableShapeTests: XCTestCase {

  private let shortBodyRow = """
    <table><thead><tr><th>Name</th><th>Value</th><th>Note</th></tr></thead>
    <tbody><tr><td>a</td><td>1</td><td>x</td></tr><tr><td>b</td><td>2</td></tr></tbody></table>
    """

  private let longBodyRow = """
    <table><thead><tr><th>A</th><th>B</th></tr></thead>
    <tbody><tr><td>1</td><td>2</td><td>3</td></tr></tbody></table>
    """

  private let emptyBodyRowWithoutHeader = """
    <table><tbody><tr></tr></tbody></table>
    """

  private let emptyHeaderRow = """
    <table><thead><tr></tr></thead><tbody><tr><td>a</td><td>b</td></tr></tbody></table>
    """

  private let wellFormed = """
    <table><thead><tr><th>A</th><th>B</th></tr></thead>
    <tbody><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></tbody></table>
    """

  // MARK: - Table data

  private func tableData(_ html: String) -> (alignments: [RawTableColumnAlignment], rows: [RawTableRow]) {
    BlockNode.htmlBlock(content: html).extractTableData(from: html)
  }

  private func texts(_ row: RawTableRow) -> [String] {
    row.cells.map { $0.content.renderPlainText() }
  }

  func testShortRowIsPaddedToHeaderWidth() {
    let data = tableData(shortBodyRow)
    XCTAssertEqual(data.alignments.count, 3)
    XCTAssertEqual(data.rows.map(\.cells.count), [3, 3, 3])
    XCTAssertEqual(texts(data.rows[2]), ["b", "2", ""])
  }

  func testLongRowIsTrimmedToHeaderWidth() {
    // Same as cmark does for pipe tables; the views never drew the extra cell anyway.
    let data = tableData(longBodyRow)
    XCTAssertEqual(data.alignments.count, 2)
    XCTAssertEqual(data.rows.map(\.cells.count), [2, 2])
    XCTAssertEqual(texts(data.rows[1]), ["1", "2"])
  }

  func testEmptyRowWithoutHeaderGetsOneEmptyCell() {
    let data = tableData(emptyBodyRowWithoutHeader)
    XCTAssertEqual(data.alignments.count, 1)
    XCTAssertEqual(data.rows.map(\.cells.count), [1])
  }

  func testEmptyHeaderRowGetsOneEmptyCell() {
    let data = tableData(emptyHeaderRow)
    XCTAssertEqual(data.alignments.count, 1)
    XCTAssertEqual(data.rows.map(\.cells.count), [1, 1])
    XCTAssertEqual(texts(data.rows[0]), [""])
  }

  func testWellFormedTableIsUnchanged() {
    let data = tableData(wellFormed)
    XCTAssertEqual(data.alignments, [.none, .none])
    XCTAssertEqual(data.rows.map(texts), [["A", "B"], ["1", "2"], ["3", "4"]])
  }

  func testPipeTableShortRowIsAlreadyRectangular() {
    // Guard for the claim above: the cmark path stays rectangular on its own.
    let content = MarkdownContent("| A | B | C |\n|---|---|---|\n| 1 | 2 |\n| 1 | 2 | 3 | 4 |")
    guard case .table(let alignments, let rows) = content.blocks.first else {
      return XCTFail("expected a table, got \(content.blocks)")
    }
    XCTAssertEqual(alignments.count, 3)
    XCTAssertEqual(rows.map(\.cells.count), [3, 3, 3])
  }

  // MARK: - Rendering (crashed before the fix)

  private func render<V: View>(_ view: V) {
    let renderer = ImageRenderer(content: view.frame(width: 320))
    XCTAssertNotNil(renderer.uiImage)
  }

  private var irregularTables: [String] {
    [shortBodyRow, longBodyRow, emptyBodyRowWithoutHeader, emptyHeaderRow, wellFormed]
  }

  func testMarkdownRendersIrregularHTMLTables() {
    for html in irregularTables {
      render(Markdown(html))
    }
  }

  func testTableViewRendersIrregularHTMLTables() {
    for html in irregularTables {
      let data = tableData(html)
      render(TableView(columnAlignments: data.alignments, rows: data.rows))
    }
  }

  func testCompatTableViewRendersIrregularHTMLTables() {
    // iOS 14/15 path. It is not availability-gated, so it can run on any simulator.
    for html in irregularTables {
      let data = tableData(html)
      render(CompatTableView(columnAlignments: data.alignments, rows: data.rows))
    }
  }
}
