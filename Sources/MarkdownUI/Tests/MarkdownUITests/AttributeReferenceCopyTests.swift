import XCTest

@testable import SendbirdMarkdownUI

/// `^[text][x]` references to a `^[x]: value` attribute reference definition.
///
/// cmark copied the whole definition value into every reference. One 66KB message with 2,000
/// references to a 50KB value grew resident memory by about 126MB in a Release build on the
/// iOS 26.4 simulator. MarkdownUI never reads attribute values, so references no longer copy it.
/// The definition can sit at the top level, in a quote, in a list item, or have a label split
/// over two lines; cmark registers all of them.
///
/// Pages freed by one test stay with the allocator and the next test in the same process can reuse
/// them, so only the first memory test of a run is sure to see the copies. Run a test alone to see
/// its own number.
final class AttributeReferenceCopyTests: XCTestCase {

  private let references = Array(repeating: "^[a][x]", count: 2_000).joined(separator: " ")
  private let value = "k: '" + String(repeating: "v", count: 50_000) + "'"

  /// Resident memory of the test process after returning freed pages to the system, so each
  /// measurement starts from memory that is really in use.
  private func residentMB() -> Double {
    malloc_zone_pressure_relief(nil, 0)
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    XCTAssertEqual(result, KERN_SUCCESS)
    return Double(info.resident_size) / 1_048_576
  }

  private func assertReferencesDoNotCopy(definition: String, file: StaticString = #filePath, line: UInt = #line) {
    let markdown = self.references + "\n\n" + definition

    let before = self.residentMB()
    let blocks = [BlockNode](markdown: markdown)
    let grown = self.residentWithoutRelief() - before

    // The definition is used: every reference keeps only its text.
    XCTAssertTrue(blocks.renderPlainText().hasPrefix("a a a"), file: file, line: line)
    // Copying the value into every reference takes about 126MB. The message itself is 0.07MB.
    print("resident memory grew by \(grown)MB")
    XCTAssertLessThan(grown, 20, "resident memory grew by \(grown)MB", file: file, line: line)
  }

  /// Read without returning pages first: pages cmark freed after the parse are still resident.
  private func residentWithoutRelief() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
    _ = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    return Double(info.resident_size) / 1_048_576
  }

  func testTopLevelDefinition() {
    self.assertReferencesDoNotCopy(definition: "^[x]: " + self.value)
  }

  func testDefinitionInAQuote() {
    self.assertReferencesDoNotCopy(definition: "> ^[x]: " + self.value)
  }

  func testDefinitionInAListItem() {
    self.assertReferencesDoNotCopy(definition: "- ^[x]: " + self.value)
  }

  func testDefinitionWithALabelOverTwoLines() {
    self.assertReferencesDoNotCopy(definition: "^[x\n]: " + self.value)
  }

  func testInlineAttributeIsUnchanged() {
    XCTAssertEqual([BlockNode](markdown: "^[글](k: v)"), [.paragraph(content: [.text("글")])])
  }
}
