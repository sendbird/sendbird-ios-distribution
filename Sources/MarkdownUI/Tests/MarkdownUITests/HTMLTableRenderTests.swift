import SwiftUI
import UIKit
import XCTest

@testable import SendbirdMarkdownUI

/// HTML `<table>` blocks are drawn by `TableView` (iOS 16+) and `CompatTableView` (iOS 14/15),
/// which read `rows[row].cells[column]` for every column. A row with fewer cells than the
/// column count used to read past the end of `cells` and terminate the app.
/// Each test lays the view out in a window so SwiftUI evaluates every cell.
final class HTMLTableRenderTests: XCTestCase {

  private func layOut<V: View>(_ view: V) {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = UIHostingController(rootView: view)
    window.makeKeyAndVisible()
    window.rootViewController?.view.setNeedsLayout()
    window.rootViewController?.view.layoutIfNeeded()
    window.isHidden = true
  }

  // MARK: - Markdown with HTML tables

  func testBodyRowShorterThanHeader() {
    layOut(Markdown("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td>C</td></tr></tbody></table>"))
  }

  func testEmptyBodyRow() {
    layOut(Markdown("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr></tr></tbody></table>"))
  }

  func testEmptyBodyRowWithoutHeader() {
    layOut(Markdown("<table><tbody><tr><td>A</td></tr><tr></tr></tbody></table>"))
  }

  func testEmptyHeaderRow() {
    layOut(Markdown("<table><thead><tr></tr></thead><tbody><tr><td>A</td></tr></tbody></table>"))
  }

  func testColspanCell() {
    layOut(Markdown("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td colspan=\"2\">C</td></tr></tbody></table>"))
  }

  // MARK: - Views given ragged rows directly

  private let raggedRows = [
    RawTableRow(cells: [RawTableCell(content: [.text("A")]), RawTableCell(content: [.text("B")])]),
    RawTableRow(cells: [RawTableCell(content: [.text("C")])]),
    RawTableRow(cells: []),
  ]

  func testTableViewToleratesRaggedRows() throws {
    guard #available(iOS 16.0, *) else { throw XCTSkip("TableView needs iOS 16") }
    layOut(TableView(columnAlignments: [.none, .none], rows: raggedRows))
  }

  func testCompatTableViewToleratesRaggedRows() {
    layOut(CompatTableView(columnAlignments: [.none, .none], rows: raggedRows))
  }
}
