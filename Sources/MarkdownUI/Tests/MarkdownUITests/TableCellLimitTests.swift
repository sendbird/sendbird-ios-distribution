import SwiftUI
import UIKit
import XCTest

@testable import SendbirdMarkdownUI

/// Tables with a very large number of cells.
///
/// `TableView` (a `Grid`) and `CompatTableView` build every cell at once while SwiftUI lays out
/// the message on the main thread. The time grows with the number of cells: about 0.2s for 1,000
/// cells and 2.8s for 10,000 cells on the iOS 26.4 simulator. The views now draw at most 1,000
/// cells: the rows that fit in 1,000 cells (header included) and the rest are not drawn.
@MainActor
final class TableCellLimitTests: XCTestCase {

  /// Generous upper bound. 1,000 cells take about 0.2s.
  private let limit: TimeInterval = 1.0

  private func markdownTable(columns: Int, rows: Int) -> String {
    let header = "|" + (0..<columns).map { "h\($0)" }.joined(separator: "|") + "|"
    let delimiter = "|" + String(repeating: "---|", count: columns)
    let row = "|" + Array(repeating: "v", count: columns).joined(separator: "|") + "|"
    return ([header, delimiter] + Array(repeating: row, count: rows)).joined(separator: "\n")
  }

  private func rawRows(columns: Int, rows: Int) -> [RawTableRow] {
    (0..<rows).map { r in
      RawTableRow(cells: (0..<columns).map { c in RawTableCell(content: [.text("r\(r)c\(c)")]) })
    }
  }

  private func height<V: View>(_ view: V) -> CGFloat {
    let controller = UIHostingController(rootView: view)
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.greatestFiniteMagnitude)).height
  }

  @available(iOS 16.0, *)
  private func renderTime(_ text: String) -> TimeInterval {
    let start = ProcessInfo.processInfo.systemUptime
    let renderer = ImageRenderer(content: Markdown(text).frame(width: 320))
    XCTAssertNotNil(renderer.uiImage, "the table must render")
    return ProcessInfo.processInfo.systemUptime - start
  }

  func testTableWithTenThousandCellsRendersQuickly() throws {
    guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
    let elapsed = renderTime(markdownTable(columns: 20, rows: 500))
    XCTAssertLessThan(elapsed, limit, "20 x 500 table took \(elapsed)s")
  }

  func testTableViewDrawsOnlyTheRowsThatFitInOneThousandCells() throws {
    guard #available(iOS 16.0, *) else { throw XCTSkip("TableView needs iOS 16") }
    // One column: the header and 999 rows fill 1,000 cells.
    let atLimit = height(TableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 1_000)))
    let overLimit = height(TableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 1_500)))
    XCTAssertEqual(overLimit, atLimit, accuracy: 0.5)
  }

  func testCompatTableViewDrawsOnlyTheRowsThatFitInOneThousandCells() {
    let atLimit = height(CompatTableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 1_000)))
    let overLimit = height(CompatTableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 1_500)))
    XCTAssertEqual(overLimit, atLimit, accuracy: 0.5)
  }

  // MARK: - Unchanged results

  func testTablesUnderTheLimitKeepEveryRow() throws {
    guard #available(iOS 16.0, *) else { throw XCTSkip("TableView needs iOS 16") }
    let fewer = height(TableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 999)))
    let atLimit = height(TableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 1_000)))
    XCTAssertGreaterThan(atLimit, fewer, "the 1,000th row must still be drawn")
    let compatFewer = height(CompatTableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 999)))
    let compatAtLimit = height(CompatTableView(columnAlignments: [.none], rows: rawRows(columns: 1, rows: 1_000)))
    XCTAssertGreaterThan(compatAtLimit, compatFewer, "the 1,000th row must still be drawn")
  }

  // MARK: - Links in cells that are not drawn

  /// `clickableLinks()` feeds the VoiceOver link actions, so it must list only the links that are drawn.
  func testClickableLinksSkipRowsThatAreNotDrawn() {
    // One column: the header and data rows 0...998 fill 1,000 cells. Row 999 is not drawn.
    let rows = (0..<1_000).map { index -> String in
      switch index {
      case 998: return "|[kept](https://e.com/kept)|"
      case 999: return "|[dropped](https://e.com/dropped)|"
      default: return "|v|"
      }
    }
    let markdown = (["|h|", "|---|"] + rows).joined(separator: "\n")
    let links = MarkdownContent(markdown).clickableLinks().map(\.url.absoluteString)
    XCTAssertEqual(links, ["https://e.com/kept"])
  }

  func testClickableLinksSkipColumnsThatAreNotDrawn() {
    // 1,001 columns: only the header row of the first 1,000 columns is drawn.
    let header = (0..<1_001).map { index -> String in
      switch index {
      case 999: return "[kept](https://e.com/kept)"
      case 1_000: return "[dropped](https://e.com/dropped)"
      default: return "h"
      }
    }
    let markdown = [
      "|" + header.joined(separator: "|") + "|",
      "|" + String(repeating: "---|", count: 1_001),
      "|" + Array(repeating: "[row](https://e.com/row)", count: 1_001).joined(separator: "|") + "|",
    ].joined(separator: "\n")
    let links = MarkdownContent(markdown).clickableLinks().map(\.url.absoluteString)
    XCTAssertEqual(links, ["https://e.com/kept"])
  }

  func testClickableLinksKeepEveryLinkInSmallTables() {
    let markdown = "|a|b|\n|---|---|\n|[one](https://e.com/1)|[two](https://e.com/2)|"
    let links = MarkdownContent(markdown).clickableLinks().map(\.url.absoluteString)
    XCTAssertEqual(links, ["https://e.com/1", "https://e.com/2"])
  }

  // MARK: - Limit edge cases

  func testLimitKeepsWholeRowsWhenTheColumnCountDoesNotDivideOneThousand() {
    let limited = TableCellLimit.limit(columnAlignments: Array(repeating: .none, count: 3), rows: rawRows(columns: 3, rows: 400))
    XCTAssertEqual(limited.columnAlignments.count, 3)
    XCTAssertEqual(limited.rows.count, 333)
    XCTAssertTrue(limited.rows.allSatisfy { $0.cells.count == 3 })
  }

  func testLimitLeavesEmptyTablesAlone() {
    let limited = TableCellLimit.limit(columnAlignments: [.none, .none], rows: [])
    XCTAssertEqual(limited.columnAlignments.count, 2)
    XCTAssertTrue(limited.rows.isEmpty)
  }

  func testLimitHandlesTablesWithoutColumns() {
    let rows = Array(repeating: RawTableRow(cells: []), count: 2_000)
    let limited = TableCellLimit.limit(columnAlignments: [], rows: rows)
    XCTAssertTrue(limited.columnAlignments.isEmpty)
    XCTAssertEqual(limited.rows.count, 1_000)
  }

  func testLimitTrimsRowsThatAreLongerThanTheKeptColumns() {
    let rows = [RawTableRow(cells: (0..<1_200).map { _ in RawTableCell(content: [.text("x")]) })]
      + rawRows(columns: 1_001, rows: 3)
    let limited = TableCellLimit.limit(columnAlignments: Array(repeating: .none, count: 1_001), rows: rows)
    XCTAssertEqual(limited.columnAlignments.count, 1_000)
    XCTAssertEqual(limited.rows.count, 1)
    XCTAssertEqual(limited.rows.first?.cells.count, 1_000)
  }
}
