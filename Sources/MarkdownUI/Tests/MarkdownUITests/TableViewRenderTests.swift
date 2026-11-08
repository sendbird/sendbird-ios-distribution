import SwiftUI
import UIKit
import XCTest

@testable import SendbirdMarkdownUI

/// Bypass parsing to exercise the views' fallback for short and empty rows.
@MainActor
final class TableViewRenderTests: XCTestCase {
  private let raggedRows = [
    RawTableRow(cells: [RawTableCell(content: [.text("A")]), RawTableCell(content: [.text("B")])]),
    RawTableRow(cells: [RawTableCell(content: [.text("C")])]),
    RawTableRow(cells: []),
  ]

  private func layOut<V: View>(_ view: V) {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = UIHostingController(rootView: view)
    window.makeKeyAndVisible()
    window.rootViewController?.view.setNeedsLayout()
    window.rootViewController?.view.layoutIfNeeded()
    window.isHidden = true
  }

  func testTableViewToleratesRaggedRows() throws {
    guard #available(iOS 16.0, *) else { throw XCTSkip("TableView needs iOS 16") }
    layOut(TableView(columnAlignments: [.none, .none], rows: raggedRows))
  }

  func testCompatTableViewToleratesRaggedRows() {
    layOut(CompatTableView(columnAlignments: [.none, .none], rows: raggedRows))
  }
}
