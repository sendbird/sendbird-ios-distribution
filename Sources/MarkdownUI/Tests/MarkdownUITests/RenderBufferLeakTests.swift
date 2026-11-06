import XCTest

@testable import SendbirdMarkdownUI

/// `MarkdownContent.renderMarkdown()`, `renderPlainText()` and `renderHTML()` copy the
/// `char *` that `cmark_render_*` returns. cmark hands ownership of that buffer to the
/// caller (`cmark-gfm.h`), so a call that does not free it leaks the whole output.
final class RenderBufferLeakTests: XCTestCase {

  /// About 30KB of output per call, so a leak shows up far above allocator noise.
  private let content = MarkdownContent(
    String(repeating: "Paragraph with **bold**, `code` and a [link](https://example.com).\n\n", count: 400)
  )

  private func bytesInUse() -> Int {
    var stats = malloc_statistics_t()
    malloc_zone_statistics(nil, &stats)
    return Int(stats.size_in_use)
  }

  /// Bytes still allocated after calling `render` `count` times.
  private func retainedBytes(calls count: Int, _ render: () -> String) -> (retained: Int, outputSize: Int) {
    let outputSize = render().utf8.count  // warm-up, also allocates any one-time state
    let before = bytesInUse()
    for _ in 0..<count {
      autoreleasepool { _ = render() }
    }
    return (bytesInUse() - before, outputSize)
  }

  private func assertDoesNotLeak(_ name: String, _ render: () -> String, file: StaticString = #filePath, line: UInt = #line) {
    let calls = 100
    let result = retainedBytes(calls: calls, render)
    print("\(name): \(result.retained) bytes retained after \(calls) calls, output \(result.outputSize) bytes")
    XCTAssertGreaterThan(result.outputSize, 10_000, "\(name) output is too small to measure", file: file, line: line)
    // A leak keeps every output: about calls * outputSize bytes. Allow up to two outputs of noise.
    XCTAssertLessThan(
      result.retained, result.outputSize * 2,
      "\(name) kept \(result.retained) bytes after \(calls) calls (output \(result.outputSize) bytes)",
      file: file, line: line
    )
  }

  func testRenderMarkdownFreesTheCmarkBuffer() {
    assertDoesNotLeak("renderMarkdown") { content.renderMarkdown() }
  }

  func testRenderPlainTextFreesTheCmarkBuffer() {
    assertDoesNotLeak("renderPlainText") { content.renderPlainText() }
  }

  func testRenderHTMLFreesTheCmarkBuffer() {
    assertDoesNotLeak("renderHTML") { content.renderHTML() }
  }

  func testRenderedOutputIsUnchanged() {
    let small = MarkdownContent("# Title\n\nHello **world** and `code`.\n\n> quote")
    XCTAssertEqual(small.renderMarkdown(), "# Title\n\nHello **world** and `code`.\n\n> quote")
    XCTAssertEqual(small.renderPlainText(), "Title\n\nHello world and code.\n\nquote")
    XCTAssertEqual(
      small.renderHTML(),
      "<h1>Title</h1>\n<p>Hello <strong>world</strong> and <code>code</code>.</p>\n<blockquote>\n<p>quote</p>\n</blockquote>\n"
    )
  }
}
