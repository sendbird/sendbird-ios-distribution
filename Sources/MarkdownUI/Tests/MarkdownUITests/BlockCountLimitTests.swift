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

  func testHTMLListWithFourThousandItemsLaysOutQuickly() {
    let html = "<ul>\n" + (0..<4_000).map { "<li>i\($0)</li>" }.joined(separator: "\n") + "\n</ul>"

    XCTAssertLessThan(self.layout(html).time, self.limit)
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

  // MARK: - Limit function

  func testLimitLeavesDocumentsUnderTheLimitAlone() {
    let blocks = [BlockNode](markdown: self.paragraphs(BlockCountLimit.maxBlocks))

    XCTAssertEqual(BlockCountLimit.limit(blocks), blocks)
  }

  func testLimitCountsListItemsAndTheBlocksInsideThem() {
    // The list, then each item and its paragraph: 1 + 2 × 499 = 999. The 500th item would need 2 more.
    let blocks = [BlockNode](markdown: self.listItems(600))

    guard case .bulletedList(_, let items) = BlockCountLimit.limit(blocks).first else {
      return XCTFail("the list must stay")
    }
    XCTAssertEqual(items.count, 499)
    XCTAssertEqual(items.last, RawListItem(children: [.paragraph(content: [.text("i498")])]))
  }

  func testLimitDoesNotKeepAnEmptyQuoteAtTheBoundary() {
    let blocks = [BlockNode](markdown: self.paragraphs(999) + "\n\n> quoted")

    let limited = BlockCountLimit.limit(blocks)

    XCTAssertEqual(limited.count, 999)
    XCTAssertEqual(limited.last, .paragraph(content: [.text("p998")]))
  }

  func testLimitDoesNotKeepAListWhoseFirstItemDoesNotFit() {
    // 998 paragraphs leave 2: the list takes 1 and its item needs 2 (the item and its paragraph).
    let limited = BlockCountLimit.limit([BlockNode](markdown: self.paragraphs(998) + "\n\n- x"))

    XCTAssertEqual(limited.count, 998)
    XCTAssertEqual(limited.last, .paragraph(content: [.text("p997")]))
  }

  func testLimitDoesNotKeepAnItemWhoseNestedQuoteIsEmpty() {
    // 997 paragraphs leave 3: list, item and quote fit, but the quote's paragraph does not.
    let limited = BlockCountLimit.limit([BlockNode](markdown: self.paragraphs(997) + "\n\n- > x"))

    XCTAssertEqual(limited.count, 997)
  }

  func testBlocksAfterAPartlyKeptListAreNotDrawn() {
    // 996 paragraphs leave 4: the list and its first item with its paragraph take 3. The second item
    // does not fit, so the paragraph after the list must not come back with the 1 that is left.
    let markdown = self.paragraphs(996) + "\n\n- a\n- b\n\nafter"

    let limited = BlockCountLimit.limit([BlockNode](markdown: markdown))

    XCTAssertEqual(limited.count, 997)
    XCTAssertEqual(limited.last, .bulletedList(isTight: true, items: [RawListItem(children: [.paragraph(content: [.text("a")])])]))
  }

  func testHTMLListOfUnclosedItemsLaysOutQuickly() {
    // 8,000 `<li>` tags that never close (48,000 characters). The item regex read to the end of the text from every one of them.
    let html = "<ul>\n" + String(repeating: "<li>x\n", count: 8_000) + "</ul>"

    XCTAssertLessThan(self.layout(html).time, self.limit)
  }

  func testHTMLListItemScanMatchesTheRegex() {
    let regex = try! NSRegularExpression(pattern: "<li[^>]*>(.*?)</li>", options: [.caseInsensitive, .dotMatchesLineSeparators])
    let samples = [
      "<ul><li>a</li><li class=\"x\">b</li></ul>",
      "<UL>\n<LI>대문자</LI>\n<li>\n줄바꿈\n</li>\n</UL>",
      "<ul><li>a<ul><li>b</li></ul></li><li>c</li></ul>",
      "<ul><li>열림만<li>둘째</li></ul>",
      "<ul><li>닫힘 없음\n<li>또 없음</ul>",
      "<ul><link rel=x><li>링크 태그 뒤</li></ul>",
      "<ol><li>😀 이모지</li><li></li></ol>",
    ]
    for html in samples {
      let expected = regex.matches(in: html, range: NSRange(html.startIndex..., in: html)).map {
        String(html[Range($0.range(at: 1), in: html)!])
      }
      XCTAssertEqual(BlockNode.listItemContents(in: html), expected, html)
    }
  }

  func testHTMLListSharesTheDocumentLimit() {
    // 990 paragraphs leave 10: the list takes 1 and each item 2, so 4 items fit.
    let html = "<ul>\n" + (0..<100).map { "<li>h\($0)</li>" }.joined(separator: "\n") + "\n</ul>"

    let limited = BlockCountLimit.limit([BlockNode](markdown: self.paragraphs(990) + "\n\n" + html))

    XCTAssertEqual(limited.count, 991)
    XCTAssertEqual(
      limited.last,
      .bulletedList(isTight: true, items: (0..<4).map { RawListItem(children: [.paragraph(content: [.text("h\($0)")])]) })
    )
  }

  func testHTMLListUnderTheLimitStaysHTML() {
    let html = "<ol>\n<li>a</li>\n<li>b</li>\n</ol>"
    let blocks = [BlockNode](markdown: html)

    XCTAssertEqual(BlockCountLimit.limit(blocks), blocks)
  }

  func testLimitKeepsTheCheckedStateOfTaskItems() {
    let taskList = BlockNode.taskList(
      isTight: true,
      items: (0..<600).map { .init(isCompleted: $0 % 2 == 0, children: [.paragraph(content: [.text("t\($0)")])]) }
    )

    guard case .taskList(_, let items) = BlockCountLimit.limit([taskList]).first else {
      return XCTFail("the task list must stay")
    }
    XCTAssertEqual(items.count, 499)
    XCTAssertEqual(items.map(\.isCompleted), (0..<499).map { $0 % 2 == 0 })
  }
}
