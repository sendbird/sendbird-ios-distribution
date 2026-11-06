import Foundation
@_implementationOnly import cmark_gfm
@_implementationOnly import cmark_gfm_extensions

// 중첩 깊이 상한. 이보다 깊은 노드는 서식을 버리고 글자만 남긴다.
// C 트리를 Swift 모델로 바꾸는 코드, SwiftUI 뷰 생성, 중첩 배열 해제가 모두 단계마다 재귀해서
// `>`나 `**`를 수천 번 겹친 메시지가 main 스레드 스택(기기 1MB)을 넘겨 앱이 죽었다.
// 32로 두면 2만 자 안에서 만들 수 있는 가장 깊은 입력도 렌더가 Debug 빌드에서 약 290KB로 끝난다.
let maxMarkdownNestingDepth = 32

extension Array where Element == BlockNode {
  init(markdown: String) {
    let blocks = UnsafeNode.parseMarkdown(markdown) { document in
      document.children.compactMap { BlockNode(unsafeNode: $0, depth: 1) }
    }
    self.init(blocks ?? .init())
  }

  func renderMarkdown() -> String {
    UnsafeNode.makeDocument(self) { document in
      String(cmarkRenderResult: cmark_render_commonmark(document, CMARK_OPT_DEFAULT, 0))
    } ?? ""
  }

  func renderPlainText() -> String {
    UnsafeNode.makeDocument(self) { document in
      String(cmarkRenderResult: cmark_render_plaintext(document, CMARK_OPT_DEFAULT, 0))
    } ?? ""
  }

  func renderHTML() -> String {
    UnsafeNode.makeDocument(self) { document in
      String(cmarkRenderResult: cmark_render_html(document, CMARK_OPT_DEFAULT, nil))
    } ?? ""
  }
}

extension String {
  // cmark_render_*가 돌려준 버퍼는 호출한 쪽이 해제해야 한다(cmark-gfm.h). 복사한 뒤 바로 free한다.
  // makeDocument가 만든 문서는 기본 allocator(calloc/free)를 쓰므로 free가 맞다.
  fileprivate init(cmarkRenderResult buffer: UnsafeMutablePointer<CChar>) {
    defer { free(buffer) }
    self.init(cString: buffer)
  }
}

extension BlockNode {
  fileprivate init?(unsafeNode: UnsafeNode, depth: Int) {
    // 자식이 없는 노드는 재귀하지 않으므로 상한을 넘어도 그대로 둔다.
    guard depth <= maxMarkdownNestingDepth || cmark_node_first_child(unsafeNode) == nil else {
      // 상한을 넘으면 더 내려가지 않고 글자만 모아 문단 하나로 둔다.
      let text = unsafeNode.flattenedText
      guard !text.isEmpty else { return nil }
      self = .paragraph(content: [.text(text)])
      return
    }
    switch unsafeNode.nodeType {
    case .blockquote:
      self = .blockquote(children: unsafeNode.children.compactMap { BlockNode(unsafeNode: $0, depth: depth + 1) })
    case .list:
      if unsafeNode.children.contains(where: \.isTaskListItem) {
        self = .taskList(
          isTight: unsafeNode.isTightList,
          items: unsafeNode.children.map { RawTaskListItem(unsafeNode: $0, depth: depth + 1) }
        )
      } else {
        switch unsafeNode.listType {
        case CMARK_BULLET_LIST:
          self = .bulletedList(
            isTight: unsafeNode.isTightList,
            items: unsafeNode.children.map { RawListItem(unsafeNode: $0, depth: depth + 1) }
          )
        case CMARK_ORDERED_LIST:
          self = .numberedList(
            isTight: unsafeNode.isTightList,
            start: unsafeNode.listStart,
            items: unsafeNode.children.map { RawListItem(unsafeNode: $0, depth: depth + 1) }
          )
        default:
          // 안전한 폴백: 알 수 없는 리스트 타입은 bullet list로 처리
          debugPrint("Warning: cmark reported a list node without a list type. Treating as bullet list.")
          self = .bulletedList(
            isTight: unsafeNode.isTightList,
            items: unsafeNode.children.map { RawListItem(unsafeNode: $0, depth: depth + 1) }
          )
        }
      }
    case .codeBlock:
      self = .codeBlock(fenceInfo: unsafeNode.fenceInfo, content: unsafeNode.literal ?? "")
    case .htmlBlock:
      self = .htmlBlock(content: unsafeNode.literal ?? "")
    case .paragraph:
      self = .paragraph(content: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) })
    case .heading:
      self = .heading(
        level: unsafeNode.headingLevel,
        content: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) }
      )
    case .table:
      self = .table(
        columnAlignments: unsafeNode.tableAlignments,
        rows: unsafeNode.children.map { RawTableRow(unsafeNode: $0, depth: depth + 1) }
      )
    case .thematicBreak:
      self = .thematicBreak
    default:
      assertionFailure("Unhandled node type '\(unsafeNode.nodeType)' in BlockNode.")
      return nil
    }
  }
}

extension RawListItem {
  fileprivate init(unsafeNode: UnsafeNode, depth: Int) {
    guard unsafeNode.nodeType == .item else {
      // 안전한 폴백: 예상치 못한 노드 타입을 빈 list item으로 처리
        debugPrint("Warning: Expected a list item but got a '\(unsafeNode.nodeType)' instead.")
      self.init(children: [])
      return
    }
    self.init(children: unsafeNode.children.compactMap { BlockNode(unsafeNode: $0, depth: depth) })
  }
}

extension RawTaskListItem {
  fileprivate init(unsafeNode: UnsafeNode, depth: Int) {
    guard unsafeNode.nodeType == .taskListItem || unsafeNode.nodeType == .item else {
      // 안전한 폴백: 예상치 못한 노드 타입을 미완료 task item으로 처리
        debugPrint("Warning: Expected a task list item but got a '\(unsafeNode.nodeType)' instead.")
      self.init(isCompleted: false, children: [])
      return
    }
    self.init(
      isCompleted: unsafeNode.isTaskListItemChecked,
      children: unsafeNode.children.compactMap { BlockNode(unsafeNode: $0, depth: depth) }
    )
  }
}

extension RawTableRow {
  fileprivate init(unsafeNode: UnsafeNode, depth: Int) {
    guard unsafeNode.nodeType == .tableRow || unsafeNode.nodeType == .tableHead else {
      // 안전한 폴백: 예상치 못한 노드 타입을 빈 table row로 처리
        debugPrint("Warning: Expected a table row but got a '\(unsafeNode.nodeType)' instead.")
      self.init(cells: [])
      return
    }
    self.init(cells: unsafeNode.children.map { RawTableCell(unsafeNode: $0, depth: depth) })
  }
}

extension RawTableCell {
  fileprivate init(unsafeNode: UnsafeNode, depth: Int) {
    guard unsafeNode.nodeType == .tableCell else {
      // 안전한 폴백: 예상치 못한 노드 타입을 빈 table cell로 처리
        debugPrint("Warning: Expected a table cell but got a '\(unsafeNode.nodeType)' instead.")
      self.init(content: [])
      return
    }
    self.init(content: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth) })
  }
}

extension InlineNode {
  fileprivate init?(unsafeNode: UnsafeNode, depth: Int) {
    // 글자, 줄바꿈, 코드처럼 자식이 없는 노드는 재귀하지 않으므로 상한을 넘어도 그대로 둔다.
    guard depth <= maxMarkdownNestingDepth || cmark_node_first_child(unsafeNode) == nil else {
      // 상한을 넘으면 더 내려가지 않고 글자만 남긴다.
      let text = unsafeNode.flattenedText
      guard !text.isEmpty else { return nil }
      self = .text(text)
      return
    }
    switch unsafeNode.nodeType {
    case .text:
      self = .text(unsafeNode.literal ?? "")
    case .softBreak:
      self = .softBreak
    case .lineBreak:
      self = .lineBreak
    case .code:
      self = .code(unsafeNode.literal ?? "")
    case .html:
      self = .text(unsafeNode.literal ?? "")
    case .emphasis:
      self = .emphasis(children: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) })
    case .strong:
      self = .strong(children: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) })
    case .strikethrough:
      self = .strikethrough(children: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) })
    case .link:
      self = .link(
        destination: unsafeNode.url ?? "",
        children: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) }
      )
    case .image:
      self = .image(
        source: unsafeNode.url ?? "",
        children: unsafeNode.children.compactMap { InlineNode(unsafeNode: $0, depth: depth + 1) }
      )
    default:
      assertionFailure("Unhandled node type '\(unsafeNode.nodeType)' in InlineNode.")
      return nil
    }
  }
}

private typealias UnsafeNode = UnsafeMutablePointer<cmark_node>

extension UnsafeNode {
  fileprivate var nodeType: NodeType {
    let typeString = String(cString: cmark_node_get_type_string(self))
    guard let nodeType = NodeType(rawValue: typeString) else {
      // 안전한 폴백: 알 수 없는 노드는 텍스트로 처리
        debugPrint("Warning: Unknown node type '\(typeString)' found. Treating as text.")
      return .text
    }
    return nodeType
  }

  fileprivate var children: UnsafeNodeSequence {
    .init(cmark_node_first_child(self))
  }

  // 이 노드 아래의 글자를 모은다. cmark iterator는 반복문으로 돌아 깊이와 상관없이 스택을 더 쓰지 않는다.
  fileprivate var flattenedText: String {
    guard let iterator = cmark_iter_new(self) else { return "" }
    defer { cmark_iter_free(iterator) }
    var text = ""
    while case let event = cmark_iter_next(iterator), event != CMARK_EVENT_DONE {
      guard let node = cmark_iter_get_node(iterator) else { continue }
      if event == CMARK_EVENT_ENTER {
        switch node.nodeType {
        case .text, .code, .html, .codeBlock, .htmlBlock:
          text += node.literal ?? ""
        case .softBreak:
          text += " "
        case .lineBreak:
          text += "\n"
        case .tableCell where cmark_node_previous(node) != nil:
          // 표 칸은 공백으로 나눈다.
          text += " "
        default:
          break
        }
      } else if [.paragraph, .heading, .tableRow, .tableHead].contains(node.nodeType) {
        text += "\n"
      }
    }
    return text.trimmingCharacters(in: .newlines)
  }

  fileprivate var literal: String? {
    cmark_node_get_literal(self).map(String.init(cString:))
  }

  fileprivate var url: String? {
    cmark_node_get_url(self).map(String.init(cString:))
  }

  fileprivate var isTaskListItem: Bool {
    self.nodeType == .taskListItem
  }

  fileprivate var listType: cmark_list_type {
    cmark_node_get_list_type(self)
  }

  fileprivate var listStart: Int {
    Int(cmark_node_get_list_start(self))
  }

  fileprivate var isTaskListItemChecked: Bool {
    cmark_gfm_extensions_get_tasklist_item_checked(self)
  }

  fileprivate var isTightList: Bool {
    cmark_node_get_list_tight(self) != 0
  }

  fileprivate var fenceInfo: String? {
    cmark_node_get_fence_info(self).map(String.init(cString:))
  }

  fileprivate var headingLevel: Int {
    Int(cmark_node_get_heading_level(self))
  }

  fileprivate var tableColumns: Int {
    Int(cmark_gfm_extensions_get_table_columns(self))
  }

  fileprivate var tableAlignments: [RawTableColumnAlignment] {
    guard self.tableColumns > 0 else { return [] }
    let alignments = cmark_gfm_extensions_get_table_alignments(self)
    guard alignments != nil else { return [] }

    return (0..<self.tableColumns).map { column in
      let ascii = alignments![column]
      let scalar = UnicodeScalar(ascii)
      let character = Character(scalar)
      return .init(rawValue: character) ?? .none
    }
  }

  fileprivate static func parseMarkdown<ResultType>(
    _ markdown: String,
    body: (UnsafeNode) throws -> ResultType
  ) rethrows -> ResultType? {
    cmark_gfm_core_extensions_ensure_registered()

    let markdown = MarkdownSyntaxBlocklist.process(markdown)

    // Create a Markdown parser and attach the GitHub syntax extensions

    let parser = cmark_parser_new(CMARK_OPT_DEFAULT)
    defer { cmark_parser_free(parser) }

    let extensionNames: Set<String> = ["tagfilter", "table"]

    for extensionName in extensionNames {
      guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
        continue
      }
      cmark_parser_attach_syntax_extension(parser, syntaxExtension)
    }

    // Parse the Markdown document

    cmark_parser_feed(parser, markdown, markdown.utf8.count)

    guard let document = cmark_parser_finish(parser) else {
      return nil
    }

    defer { cmark_node_free(document) }
    return try body(document)
  }

  fileprivate static func makeDocument<ResultType>(
    _ blocks: [BlockNode],
    body: (UnsafeNode) throws -> ResultType
  ) rethrows -> ResultType? {
    cmark_gfm_core_extensions_ensure_registered()
    guard let document = cmark_node_new(CMARK_NODE_DOCUMENT) else { return nil }
    blocks.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(document, $0) }

    defer { cmark_node_free(document) }
    return try body(document)
  }

  fileprivate static func make(_ block: BlockNode) -> UnsafeNode? {
    switch block {
    case .blockquote(let children):
      guard let node = cmark_node_new(CMARK_NODE_BLOCK_QUOTE) else { return nil }
      children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .bulletedList(let isTight, let items):
      guard let node = cmark_node_new(CMARK_NODE_LIST) else { return nil }
      cmark_node_set_list_type(node, CMARK_BULLET_LIST)
      cmark_node_set_list_tight(node, isTight ? 1 : 0)
      items.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .numberedList(let isTight, let start, let items):
      guard let node = cmark_node_new(CMARK_NODE_LIST) else { return nil }
      cmark_node_set_list_type(node, CMARK_ORDERED_LIST)
      cmark_node_set_list_tight(node, isTight ? 1 : 0)
      cmark_node_set_list_start(node, Int32(start))
      items.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .taskList(let isTight, let items):
      guard let node = cmark_node_new(CMARK_NODE_LIST) else { return nil }
      cmark_node_set_list_type(node, CMARK_BULLET_LIST)
      cmark_node_set_list_tight(node, isTight ? 1 : 0)
      items.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .codeBlock(let fenceInfo, let content):
      guard let node = cmark_node_new(CMARK_NODE_CODE_BLOCK) else { return nil }
      if let fenceInfo {
        cmark_node_set_fence_info(node, fenceInfo)
      }
      cmark_node_set_literal(node, content)
      return node
    case .htmlBlock(let content):
      guard let node = cmark_node_new(CMARK_NODE_HTML_BLOCK) else { return nil }
      cmark_node_set_literal(node, content)
      return node
    case .paragraph(let content):
      guard let node = cmark_node_new(CMARK_NODE_PARAGRAPH) else { return nil }
      content.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .heading(let level, let content):
      guard let node = cmark_node_new(CMARK_NODE_HEADING) else { return nil }
      cmark_node_set_heading_level(node, Int32(level))
      content.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .table(let columnAlignments, let rows):
      guard let table = cmark_find_syntax_extension("table"),
        let node = cmark_node_new_with_ext(ExtensionNodeTypes.shared.CMARK_NODE_TABLE, table)
      else {
        return nil
      }
      cmark_gfm_extensions_set_table_columns(node, UInt16(columnAlignments.count))
      var alignments = columnAlignments.map { $0.rawValue.asciiValue ?? 0 }
      cmark_gfm_extensions_set_table_alignments(node, UInt16(columnAlignments.count), &alignments)
      rows.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      if let header = cmark_node_first_child(node) {
        cmark_gfm_extensions_set_table_row_is_header(header, 1)
      }
      return node
    case .thematicBreak:
      guard let node = cmark_node_new(CMARK_NODE_THEMATIC_BREAK) else { return nil }
      return node
    }
  }

  fileprivate static func make(_ item: RawListItem) -> UnsafeNode? {
    guard let node = cmark_node_new(CMARK_NODE_ITEM) else { return nil }
    item.children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
    return node
  }

  fileprivate static func make(_ item: RawTaskListItem) -> UnsafeNode? {
    guard let tasklist = cmark_find_syntax_extension("tasklist"),
      let node = cmark_node_new_with_ext(CMARK_NODE_ITEM, tasklist)
    else {
      return nil
    }
    cmark_gfm_extensions_set_tasklist_item_checked(node, item.isCompleted)
    item.children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
    return node
  }

  fileprivate static func make(_ tableRow: RawTableRow) -> UnsafeNode? {
    guard let table = cmark_find_syntax_extension("table"),
      let node = cmark_node_new_with_ext(ExtensionNodeTypes.shared.CMARK_NODE_TABLE_ROW, table)
    else {
      return nil
    }
    tableRow.cells.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
    return node
  }

  fileprivate static func make(_ tableCell: RawTableCell) -> UnsafeNode? {
    guard let table = cmark_find_syntax_extension("table"),
      let node = cmark_node_new_with_ext(ExtensionNodeTypes.shared.CMARK_NODE_TABLE_CELL, table)
    else {
      return nil
    }
    tableCell.content.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
    return node
  }

  fileprivate static func make(_ inline: InlineNode) -> UnsafeNode? {
    switch inline {
    case .text(let content):
      guard let node = cmark_node_new(CMARK_NODE_TEXT) else { return nil }
      cmark_node_set_literal(node, content)
      return node
    case .softBreak:
      return cmark_node_new(CMARK_NODE_SOFTBREAK)
    case .lineBreak:
      return cmark_node_new(CMARK_NODE_LINEBREAK)
    case .code(let content):
      guard let node = cmark_node_new(CMARK_NODE_CODE) else { return nil }
      cmark_node_set_literal(node, content)
      return node
    case .html(let content):
      guard let node = cmark_node_new(CMARK_NODE_HTML_INLINE) else { return nil }
      cmark_node_set_literal(node, content)
      return node
    case .emphasis(let children):
      guard let node = cmark_node_new(CMARK_NODE_EMPH) else { return nil }
      children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .strong(let children):
      guard let node = cmark_node_new(CMARK_NODE_STRONG) else { return nil }
      children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .strikethrough(let children):
      guard let strikethrough = cmark_find_syntax_extension("strikethrough"),
        let node = cmark_node_new_with_ext(
          ExtensionNodeTypes.shared.CMARK_NODE_STRIKETHROUGH, strikethrough)
      else {
        return nil
      }
      children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .link(let destination, let children):
      guard let node = cmark_node_new(CMARK_NODE_LINK) else { return nil }
      cmark_node_set_url(node, destination)
      children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    case .image(let source, let children):
      guard let node = cmark_node_new(CMARK_NODE_IMAGE) else { return nil }
      cmark_node_set_url(node, source)
      children.compactMap(UnsafeNode.make).forEach { cmark_node_append_child(node, $0) }
      return node
    }
  }
}

private enum NodeType: String {
  case document
  case blockquote = "block_quote"
  case list
  case item
  case codeBlock = "code_block"
  case htmlBlock = "html_block"
  case customBlock = "custom_block"
  case paragraph
  case heading
  case thematicBreak = "thematic_break"
  case text
  case softBreak = "softbreak"
  case lineBreak = "linebreak"
  case code
  case html = "html_inline"
  case customInline = "custom_inline"
  case emphasis = "emph"
  case strong
  case link
  case image
  case inlineAttributes = "attribute"
  case none = "NONE"
  case unknown = "<unknown>"

  // Extensions

  case strikethrough
  case table
  case tableHead = "table_header"
  case tableRow = "table_row"
  case tableCell = "table_cell"
  case taskListItem = "tasklist"
}

private struct UnsafeNodeSequence: Sequence {
  struct Iterator: IteratorProtocol {
    private var node: UnsafeNode?

    init(_ node: UnsafeNode?) {
      self.node = node
    }

    mutating func next() -> UnsafeNode? {
      guard let node else { return nil }
      defer { self.node = cmark_node_next(node) }
      return node
    }
  }

  private let node: UnsafeNode?

  init(_ node: UnsafeNode?) {
    self.node = node
  }

  func makeIterator() -> Iterator {
    .init(self.node)
  }
}

// Extension node types are not exported in `cmark_gfm_extensions`,
// so we need to look for them in the symbol table
private struct ExtensionNodeTypes {
  let CMARK_NODE_TABLE: cmark_node_type
  let CMARK_NODE_TABLE_ROW: cmark_node_type
  let CMARK_NODE_TABLE_CELL: cmark_node_type
  let CMARK_NODE_STRIKETHROUGH: cmark_node_type

  static let shared = ExtensionNodeTypes()

  private init() {
    func findNodeType(_ name: String, in handle: UnsafeMutableRawPointer!) -> cmark_node_type? {
      guard let symbol = dlsym(handle, name) else {
        return nil
      }
      return symbol.assumingMemoryBound(to: cmark_node_type.self).pointee
    }

    let handle = dlopen(nil, RTLD_LAZY)

    self.CMARK_NODE_TABLE = findNodeType("CMARK_NODE_TABLE", in: handle) ?? CMARK_NODE_NONE
    self.CMARK_NODE_TABLE_ROW = findNodeType("CMARK_NODE_TABLE_ROW", in: handle) ?? CMARK_NODE_NONE
    self.CMARK_NODE_TABLE_CELL =
      findNodeType("CMARK_NODE_TABLE_CELL", in: handle) ?? CMARK_NODE_NONE
    self.CMARK_NODE_STRIKETHROUGH =
      findNodeType("CMARK_NODE_STRIKETHROUGH", in: handle) ?? CMARK_NODE_NONE

    dlclose(handle)
  }
}
