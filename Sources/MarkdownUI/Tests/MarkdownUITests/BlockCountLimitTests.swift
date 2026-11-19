import SwiftUI
import UIKit
import XCTest

@testable import SendbirdMarkdownUI

/// Markdown with thousands of blocks.
///
/// `BlockSequence` builds a view for every block (paragraph, list item, quote, ...) at once while
/// SwiftUI lays out the message on the main thread. 4,000 list items (16,000 characters) take about
/// 1.8s on the iOS 26.4 simulator, while the same lines in a single paragraph take 0.15s. The view
/// now draws at most 1,000 blocks per document, counting list items, and the rest is not drawn.
@MainActor
final class BlockCountLimitTests: XCTestCase {

  /// Generous upper bound. 1,000 blocks take about 0.2s.
  private let limit: TimeInterval = 1.0

  private func paragraphs(_ count: Int, _ text: (Int) -> String = { "p\($0)" }) -> String {
    (0..<count).map(text).joined(separator: "\n\n")
  }

  private func listItems(_ count: Int) -> String {
    (0..<count).map { "- i\($0)" }.joined(separator: "\n")
  }

  private func layout(_ text: String) -> (time: TimeInterval, height: CGFloat) {
    let start = ProcessInfo.processInfo.systemUptime
    let controller = UIHostingController(rootView: Markdown(text).frame(width: 320))
    let height = controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.greatestFiniteMagnitude)).height
    return (ProcessInfo.processInfo.systemUptime - start, height)
  }

  func testFourThousandListItemsLayOutQuickly() {
    let time = self.layout(self.listItems(4_000)).time

    XCTAssertLessThan(time, self.limit)
  }

  func testEightThousandParagraphsLayOutQuickly() {
    let time = self.layout(self.paragraphs(8_000)).time

    XCTAssertLessThan(time, self.limit)
  }

  func testParagraphsPastTheLimitAreNotDrawn() {
    let atTheLimit = self.layout(self.paragraphs(1_000)).height

    XCTAssertEqual(self.layout(self.paragraphs(1_500)).height, atTheLimit)
  }

  func testDocumentsUnderTheLimitKeepEveryBlock() {
    let fewer = self.layout(self.paragraphs(999)).height

    XCTAssertGreaterThan(self.layout(self.paragraphs(1_000)).height, fewer)
  }

  func testClickableLinksSkipBlocksThatAreNotDrawn() {
    let content = MarkdownContent(self.paragraphs(1_500) { "[l\($0)](https://e.com/\($0))" })

    let links = content.clickableLinks()

    XCTAssertEqual(links.count, 1_000)
    XCTAssertEqual(links.last?.url.absoluteString, "https://e.com/999")
  }

  func testClickableImagesSkipBlocksThatAreNotDrawn() {
    let content = MarkdownContent(self.paragraphs(1_500) { "![a\($0)](https://e.com/\($0).png)" })

    XCTAssertEqual(content.clickableImages().count, 1_000)
  }
}
