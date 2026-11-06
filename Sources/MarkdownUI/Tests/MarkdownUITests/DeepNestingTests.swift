import SwiftUI
import XCTest

@testable import SendbirdMarkdownUI

/// Markdown nested thousands of levels deep.
///
/// cmark builds the tree with loops, but every step after it recurses once per level:
/// turning the C tree into `BlockNode`/`InlineNode`, building the SwiftUI views and
/// text, and releasing the nested arrays. A message of up to 20,000 characters (the
/// highest `max_message_length` an app can set) is enough to run a device's main
/// thread out of stack.
@available(iOS 16.0, *)
@MainActor
final class DeepNestingTests: XCTestCase {

  /// Inputs of at most 20,000 characters, one per kind of nesting cmark allows without a limit.
  private static let strong = String(repeating: "**", count: 4_999) + "x" + String(repeating: "**", count: 4_999)
  private static let emphasis = String(repeating: "*", count: 9_999) + "x" + String(repeating: "*", count: 9_999)
  private static let blockquote = String(repeating: ">", count: 19_999) + "x"
  private static let imageAlt = String(repeating: "![", count: 3_333) + "x" + String(repeating: "](u)", count: 3_333)
  private static let linkText = "[" + String(repeating: "_", count: 9_997) + "x" + String(repeating: "_", count: 9_997) + "](u)"
  private static let quoteAndList = String(repeating: "> - ", count: 4_999) + "x"

  /// Shallow but wide: one paragraph with about 10,000 sibling inlines. Each inline becomes one
  /// `Text` joined onto the previous result, and SwiftUI resolves that chain recursively.
  private static let softBreaks = String(repeating: "a\n", count: 9_999)
  private static let hardBreaks = String(repeating: "a\\\n", count: 6_666)
  private static let emphasisRuns = String(repeating: "*a* ", count: 4_999)

  private let deepInputs: [(name: String, markdown: String)] = [
    ("strong", strong), ("emphasis", emphasis), ("blockquote", blockquote),
    ("image alt", imageAlt), ("link text", linkText), ("quote and list", quoteAndList),
    ("soft breaks", softBreaks), ("hard breaks", hardBreaks), ("emphasis runs", emphasisRuns),
  ]

  /// Stack left for MarkdownUI on a device: 1MB main thread minus what UIKit and SwiftUI
  /// already use when a collection view cell lays out its Markdown view.
  private let deviceStackBudget = 512 * 1024

  /// Default stack size of a secondary thread on iOS.
  private let secondaryThreadStack = 512 * 1024

  func testInputsFitTheLongestAllowedMessage() {
    for input in deepInputs {
      XCTAssertLessThanOrEqual(input.markdown.count, 20_000, input.name)
    }
  }

  private func parseOnBackgroundThread(_ markdown: String, file: StaticString = #filePath, line: UInt = #line) {
    var text = ""
    onThread(stackSize: secondaryThreadStack) {
      text = MarkdownContent(markdown).renderPlainText()
    }
    XCTAssertTrue(text.contains("x"), "the text inside the nesting was lost", file: file, line: line)
  }

  private func renderOnMainThread(_ markdown: String, file: StaticString = #filePath, line: UInt = #line) {
    withRemainingStack(deviceStackBudget) {
      // An image-only message renders at zero size before the image loads, and ImageRenderer
      // returns nil for that. The label keeps the size above zero; the point is not crashing.
      let renderer = ImageRenderer(content: VStack { Text("label"); Markdown(markdown) }.frame(width: 320))
      XCTAssertNotNil(renderer.uiImage, file: file, line: line)
    }
  }

  func testBackgroundParseStrong() { parseOnBackgroundThread(Self.strong) }
  func testBackgroundParseEmphasis() { parseOnBackgroundThread(Self.emphasis) }
  func testBackgroundParseBlockquote() { parseOnBackgroundThread(Self.blockquote) }
  func testBackgroundParseImageAlt() { parseOnBackgroundThread(Self.imageAlt) }
  func testBackgroundParseLinkText() { parseOnBackgroundThread(Self.linkText) }
  func testBackgroundParseQuoteAndList() { parseOnBackgroundThread(Self.quoteAndList) }

  func testMainRenderStrong() { renderOnMainThread(Self.strong) }
  func testMainRenderEmphasis() { renderOnMainThread(Self.emphasis) }
  func testMainRenderBlockquote() { renderOnMainThread(Self.blockquote) }
  func testMainRenderImageAlt() { renderOnMainThread(Self.imageAlt) }
  func testMainRenderLinkText() { renderOnMainThread(Self.linkText) }
  func testMainRenderQuoteAndList() { renderOnMainThread(Self.quoteAndList) }
  func testMainRenderSoftBreaks() { renderOnMainThread(Self.softBreaks) }
  func testMainRenderHardBreaks() { renderOnMainThread(Self.hardBreaks) }
  func testMainRenderEmphasisRuns() { renderOnMainThread(Self.emphasisRuns) }

  // MARK: - Depth limit

  private func nestedQuotes(_ depth: Int, _ innermost: BlockNode) -> BlockNode {
    (1..<depth).reduce(.blockquote(children: [innermost])) { inner, _ in .blockquote(children: [inner]) }
  }

  func testQuotesUpToTheLimitKeepTheirStructure() {
    // Quotes take levels 1...limit-1, the paragraph inside takes the last level.
    let depth = maxMarkdownNestingDepth - 1
    XCTAssertEqual(
      MarkdownContent(String(repeating: ">", count: depth) + "x").blocks,
      [nestedQuotes(depth, .paragraph(content: [.text("x")]))]
    )
  }

  func testQuotesPastTheLimitBecomePlainText() {
    let depth = maxMarkdownNestingDepth
    XCTAssertEqual(
      MarkdownContent(String(repeating: ">", count: depth + 3) + "**x** `y`\nz").blocks,
      [nestedQuotes(depth, .paragraph(content: [.text("x y z")]))]
    )
  }

  func testStrongPastTheLimitBecomesPlainText() {
    // The paragraph is level 1, so strong runs from level 2 to the limit.
    let kept = maxMarkdownNestingDepth - 1
    let markdown = String(repeating: "**", count: kept + 5) + "x" + String(repeating: "**", count: kept + 5)
    guard case .paragraph(let content) = MarkdownContent(markdown).blocks.first,
          content.count == 1, case .strong = content[0] else {
      return XCTFail("expected one strong run in a paragraph")
    }
    XCTAssertEqual(content.renderPlainText(), "x")
    XCTAssertEqual(content.depth, kept + 1)  // kept strongs + the flattened text
  }

  func testPlainTextKeepsEveryWordPastTheLimit() {
    let words = (1...5).map { "w\($0)" }
    let markdown = String(repeating: ">", count: 100) + words.joined(separator: "\n\n" + String(repeating: ">", count: 100))
    let text = MarkdownContent(markdown).renderPlainText()
    for word in words {
      XCTAssertTrue(text.contains(word), "\(word) missing from \(text)")
    }
  }

  func testHardBreakAtTheLimitIsKept() {
    // The paragraph sits at the last kept level, so its text and line break are one level past it.
    let quotes = String(repeating: ">", count: maxMarkdownNestingDepth - 1)
    let content = MarkdownContent(quotes + "a  \n" + quotes + "b")
    XCTAssertEqual(
      content.blocks,
      [nestedQuotes(maxMarkdownNestingDepth - 1, .paragraph(content: [.text("a"), .lineBreak, .text("b")]))]
    )
  }

  func testTablePastTheLimitKeepsCellsAndRowsApart() {
    let quotes = String(repeating: ">", count: maxMarkdownNestingDepth)
    let markdown = ["| first | second |", "| --- | --- |", "| alpha | beta |"].map { quotes + $0 }.joined(separator: "\n")
    XCTAssertEqual(
      MarkdownContent(markdown).blocks,
      [nestedQuotes(maxMarkdownNestingDepth, .paragraph(content: [.text("first second\nalpha beta")]))]
    )
  }

  func testCodeBlockPastTheLimitStaysACodeBlock() {
    let quotes = String(repeating: ">", count: maxMarkdownNestingDepth)
    XCTAssertEqual(
      MarkdownContent(quotes + "```swift\n" + quotes + "let a = 1\n" + quotes + "```").blocks,
      [nestedQuotes(maxMarkdownNestingDepth, .codeBlock(fenceInfo: "swift", content: "let a = 1\n"))]
    )
  }

  // MARK: - Ordinary nesting keeps its structure

  func testShallowBlockquotesAreUnchanged() {
    XCTAssertEqual(
      MarkdownContent("> > > x").blocks,
      [.blockquote(children: [.blockquote(children: [.blockquote(children: [.paragraph(content: [.text("x")])])])])]
    )
  }

  func testShallowInlineNestingIsUnchanged() {
    XCTAssertEqual(
      MarkdownContent("***a*** [**b** `c`](u) ![*d*](i)").blocks,
      [
        .paragraph(content: [
          .emphasis(children: [.strong(children: [.text("a")])]),
          .text(" "),
          .link(destination: "u", children: [.strong(children: [.text("b")]), .text(" "), .code("c")]),
          .text(" "),
          .image(source: "i", children: [.emphasis(children: [.text("d")])]),
        ])
      ]
    )
  }

  func testShallowListsAreUnchanged() {
    XCTAssertEqual(
      MarkdownContent("- a\n  - b\n    > c").blocks,
      [
        .bulletedList(isTight: true, items: [
          RawListItem(children: [
            .paragraph(content: [.text("a")]),
            .bulletedList(isTight: true, items: [
              RawListItem(children: [
                .paragraph(content: [.text("b")]),
                .blockquote(children: [.paragraph(content: [.text("c")])]),
              ])
            ]),
          ])
        ])
      ]
    )
  }
}

private extension Array where Element == InlineNode {
  /// Levels of inline nesting, counting the innermost leaf.
  var depth: Int {
    map { node -> Int in
      switch node {
      case .emphasis(let children), .strong(let children), .strikethrough(let children),
           .link(_, let children), .image(_, let children):
        return 1 + children.depth
      default:
        return 1
      }
    }.max() ?? 0
  }
}
