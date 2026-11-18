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
    _ = renderer.uiImage
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
}
