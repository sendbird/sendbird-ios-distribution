import SwiftUI

extension BlockNode: View {

  // Helper function to safely create NSRegularExpression
  private func safeRegex(pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
    do {
      return try NSRegularExpression(pattern: pattern, options: options)
    } catch {
      debugPrint("BlockNode: Failed to create regex pattern '\(pattern)': \(error)")
      return nil
    }
  }
  var body: some View {
    switch self {
    case .blockquote(let children):
      BlockquoteView(children: children)
    case .bulletedList(let isTight, let items):
      BulletedListView(isTight: isTight, items: items)
    case .numberedList(let isTight, let start, let items):
      NumberedListView(isTight: isTight, start: start, items: items)
    case .taskList(let isTight, let items):
      TaskListView(isTight: isTight, items: items)
    case .codeBlock(let fenceInfo, let content):
      CodeBlockView(fenceInfo: fenceInfo, content: content)
    case .htmlBlock(let content):
      if isHTMLTable(content) {
        parseHTMLTable(content)
      } else if isHTMLList(content) {
        parseHTMLList(content)
      } else if isHTMLHeading(content) {
        parseHTMLHeading(content)
      } else if isHTMLCode(content) {
        parseHTMLCode(content)
      } else if isHTMLBlockquote(content) {
        parseHTMLBlockquote(content)
      } else {
        ParagraphView(content: [.text(content)])
      }
    case .paragraph(let content):
      ParagraphView(content: content)
    case .heading(let level, let content):
      HeadingView(level: level, content: content)
    case .table(let columnAlignments, let rows):
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        TableView(columnAlignments: columnAlignments, rows: rows)
      } else {
        CompatTableView(columnAlignments: columnAlignments, rows: rows)
      }
    case .thematicBreak:
      ThematicBreakView()
    }
  }

  // BlockCountLimit 이 뷰와 같은 기준으로 HTML 목록을 세려고 아래 네 함수에서 private를 뺐다.
  func isHTMLTable(_ html: String) -> Bool {
    html.lowercased().contains("<table")
  }

  func isHTMLList(_ html: String) -> Bool {
    let lowered = html.lowercased()
    return lowered.contains("<ul") || lowered.contains("<ol")
  }

  private func isHTMLHeading(_ html: String) -> Bool {
    let lowered = html.lowercased()
    return lowered.contains("<h1") || lowered.contains("<h2") || lowered.contains("<h3") ||
           lowered.contains("<h4") || lowered.contains("<h5") || lowered.contains("<h6")
  }

  private func isHTMLCode(_ html: String) -> Bool {
    let lowered = html.lowercased()
    return lowered.contains("<pre") || lowered.contains("<code")
  }

  private func isHTMLBlockquote(_ html: String) -> Bool {
    html.lowercased().contains("<blockquote")
  }

  private func parseHTMLTable(_ html: String) -> some View {
    let tableData = extractTableData(from: html)

    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      return AnyView(TableView(
        columnAlignments: tableData.alignments,
        rows: tableData.rows
      ))
    } else {
      return AnyView(CompatTableView(
        columnAlignments: tableData.alignments,
        rows: tableData.rows
      ))
    }
  }

  func isHTMLOrderedList(_ html: String) -> Bool {
    html.lowercased().contains("<ol")
  }

  private func parseHTMLList(_ html: String) -> some View {
    let isOrdered = isHTMLOrderedList(html)
    let items = extractListItems(from: html)

    if isOrdered {
      return AnyView(NumberedListView(isTight: true, start: 1, items: items))
    } else {
      return AnyView(BulletedListView(isTight: true, items: items))
    }
  }

  private func parseHTMLHeading(_ html: String) -> some View {
    let (level, content) = extractHeading(from: html)
    return AnyView(HeadingView(level: level, content: [.text(content)]))
  }

  private func parseHTMLCode(_ html: String) -> some View {
    let content = extractCodeContent(from: html)
    return AnyView(CodeBlockView(fenceInfo: nil, content: content))
  }

  private func parseHTMLBlockquote(_ html: String) -> some View {
    let content = extractBlockquoteContent(from: html)
    let paragraph = BlockNode.paragraph(content: [.text(content)])
    return AnyView(BlockquoteView(children: [paragraph]))
  }

  // 칸 수 맞춤을 테스트에서 확인하려고 private를 뺐다.
  func extractTableData(from html: String) -> (alignments: [RawTableColumnAlignment], rows: [RawTableRow]) {
    let cleanedHTML = html
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

    let bodyPattern = "<tbody[^>]*>(.*?)</tbody>"
    guard let bodyRegex = safeRegex(pattern: bodyPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return (alignments: [RawTableColumnAlignment.none], rows: [])
    }

    var rows: [RawTableRow] = []
    var columnCount = 0

    if let headerContent = extractHeaderRow(from: cleanedHTML) {
      let headerCells = extractCells(from: headerContent)
      columnCount = headerCells.count
      rows.append(RawTableRow(cells: headerCells.map { RawTableCell(content: [.text($0)]) }))
    }

    if let bodyMatch = bodyRegex.firstMatch(in: cleanedHTML, range: NSRange(cleanedHTML.startIndex..., in: cleanedHTML)),
       let bodyRange = Range(bodyMatch.range(at: 1), in: cleanedHTML) {
      let bodyContent = String(cleanedHTML[bodyRange])
      let bodyRows = extractRows(from: bodyContent)

      for rowContent in bodyRows {
        let cells = extractCells(from: rowContent)
        rows.append(RawTableRow(cells: cells.map { RawTableCell(content: [.text($0)]) }))
      }
    }

    let alignments = Array(repeating: RawTableColumnAlignment.none, count: max(columnCount, 1))
    // TableView, CompatTableView는 열 수만큼 cells[column]을 읽는다.
    // 칸이 모자란 행은 빈 칸으로 채우고 넘치는 칸은 잘라, 행마다 칸 수를 열 수와 맞춘다(cmark pipe 표와 같은 규칙).
    let emptyCell = RawTableCell(content: [])
    let shapedRows = rows.map { row in
      RawTableRow(
        cells: Array(row.cells.prefix(alignments.count))
          + Array(repeating: emptyCell, count: max(alignments.count - row.cells.count, 0))
      )
    }
    return (alignments: alignments, rows: shapedRows)
  }

  // 첫 <thead> 뒤에서 마지막 </thead> 앞까지의 첫 행을 머리글로 쓴다. 예전 정규식
  // <thead[^>]*>.*?<tr[^>]*>(.*?)</tr>.*?</thead> 와 같은 행을 고른다.
  // 예전 정규식은 </thead> 나 </tr> 가 없으면 <tr> 마다 글 끝까지 다시 훑어, 행 600개에 18초가 걸렸다.
  // 여기서는 <thead, >, 마지막 </thead>, <tr, >, </tr> 를 차례로 한 번씩만 찾는다.
  // 마지막 </thead> 를 쓰는 것은 속성 값이나 주석 안의 </thead> 에서 범위가 잘리지 않게 하려는 것이다.
  // 정규식처럼 UTF-16 단위로 글자 그대로 비교한다(.literal). 그렇지 않으면 결합 문자가 붙은 > 를 건너뛴다.
  private func extractHeaderRow(from html: String) -> String? {
    let text = html as NSString
    func find(_ target: String, from start: Int, backwards: Bool = false) -> NSRange? {
      var options: NSString.CompareOptions = [.caseInsensitive, .literal]
      if backwards { options.insert(.backwards) }
      let found = text.range(of: target, options: options, range: NSRange(location: start, length: text.length - start))
      return found.location == NSNotFound ? nil : found
    }
    guard let open = find("<thead", from: 0),
          let openEnd = find(">", from: NSMaxRange(open)),
          let close = find("</thead>", from: NSMaxRange(openEnd), backwards: true),
          let row = find("<tr", from: NSMaxRange(openEnd)), NSMaxRange(row) <= close.location,
          let rowStartEnd = find(">", from: NSMaxRange(row)), NSMaxRange(rowStartEnd) <= close.location,
          let rowClose = find("</tr>", from: NSMaxRange(rowStartEnd)), NSMaxRange(rowClose) <= close.location
    else {
      return nil
    }
    return text.substring(with: NSRange(location: NSMaxRange(rowStartEnd), length: rowClose.location - NSMaxRange(rowStartEnd)))
  }

  private func extractRows(from html: String) -> [String] {
    let rowPattern = "<tr[^>]*>(.*?)</tr>"
    guard let regex = safeRegex(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return []
    }
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

    return matches.compactMap { match in
      guard let range = Range(match.range(at: 1), in: html) else { return nil }
      return String(html[range])
    }
  }

  private func extractCells(from html: String) -> [String] {
    let cellPattern = "<t[hd][^>]*>(.*?)</t[hd]>"
    guard let regex = safeRegex(pattern: cellPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return []
    }
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

    return matches.compactMap { match in
      guard let range = Range(match.range(at: 1), in: html) else { return nil }
      let cellContent = String(html[range])
      return cellContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  func extractListItems(from html: String) -> [RawListItem] {
    return Self.listItemContents(in: html).map { content in
      let itemContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

      // li 태그의 직접적인 텍스트 내용만 추출 (중첩된 리스트 제외)
      let directText = extractDirectTextOnly(from: itemContent)
      let paragraph = BlockNode.paragraph(content: [.text(directText)])
      return RawListItem(children: [paragraph])
    }
  }

  /// `<li[^>]*>(.*?)</li>`(대소문자 무시, 줄바꿈 포함)와 같은 결과를 한 번 훑어 낸다.
  /// 정규식은 닫는 `</li>`가 없는 `<li`마다 글 끝까지 다시 훑어, 닫히지 않은 `<li>`가 수천 개면 main이 1초 넘게 멈췄다.
  /// 어떤 `<li` 뒤에 `>`나 `</li>`가 없으면 그 뒤의 `<li`에도 없으므로 거기서 멈춘다.
  static func listItemContents(in html: String) -> [String] {
    let bytes = Array(html.utf8)
    func lower(_ byte: UInt8) -> UInt8 { byte >= 65 && byte <= 90 ? byte | 0x20 : byte }
    func find(_ pattern: [UInt8], from start: Int) -> Int? {
      guard pattern.count <= bytes.count else { return nil }
      var index = start
      while index + pattern.count <= bytes.count {
        var matched = true
        for offset in 0..<pattern.count where lower(bytes[index + offset]) != pattern[offset] {
          matched = false
          break
        }
        if matched { return index }
        index += 1
      }
      return nil
    }
    let open = Array("<li".utf8)
    let close = Array("</li>".utf8)
    var contents: [String] = []
    var index = 0
    while let start = find(open, from: index),
          let tagEnd = find([UInt8(ascii: ">")], from: start + open.count),
          let end = find(close, from: tagEnd + 1) {
      contents.append(String(decoding: bytes[(tagEnd + 1)..<end], as: UTF8.self))
      index = end + close.count
    }
    return contents
  }

  private func extractHeading(from html: String) -> (level: Int, content: String) {
    let headingPattern = "<h([1-6])[^>]*>(.*?)</h[1-6]>"
    guard let regex = safeRegex(pattern: headingPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return (level: 1, content: "")
    }

    if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
       let levelRange = Range(match.range(at: 1), in: html),
       let contentRange = Range(match.range(at: 2), in: html) {
      let level = Int(String(html[levelRange])) ?? 1
      let content = String(html[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
      return (level: level, content: content)
    }

    return (level: 1, content: "")
  }

  private func extractCodeContent(from html: String) -> String {
    // <pre><code>content</code></pre> 또는 <code>content</code>
    let codePattern = "<(?:pre[^>]*>)?<code[^>]*>(.*?)</code>(?:</pre>)?"
    guard let regex = safeRegex(pattern: codePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return html.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
       let range = Range(match.range(at: 1), in: html) {
      return String(html[range])
    }

    return html.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func extractBlockquoteContent(from html: String) -> String {
    let blockquotePattern = "<blockquote[^>]*>(.*?)</blockquote>"
    guard let regex = safeRegex(pattern: blockquotePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return html.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
       let range = Range(match.range(at: 1), in: html) {
      return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return html.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func extractDirectTextOnly(from html: String) -> String {
    // 중첩된 리스트 태그 (<ul> 또는 <ol>부터 해당 닫는 태그까지) 제거
    var cleanedString = html

    // ul 태그와 그 내용 제거
    let ulPattern = "<ul[^>]*>.*?</ul>"
    if let ulRegex = safeRegex(pattern: ulPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
      cleanedString = ulRegex.stringByReplacingMatches(
        in: cleanedString,
        options: [],
        range: NSRange(cleanedString.startIndex..., in: cleanedString),
        withTemplate: ""
      )
    }

    // ol 태그와 그 내용 제거
    let olPattern = "<ol[^>]*>.*?</ol>"
    if let olRegex = safeRegex(pattern: olPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
      cleanedString = olRegex.stringByReplacingMatches(
        in: cleanedString,
        options: [],
        range: NSRange(cleanedString.startIndex..., in: cleanedString),
        withTemplate: ""
      )
    }

    // 남은 HTML 태그 제거
    let tagPattern = "<[^>]+>"
    if let tagRegex = safeRegex(pattern: tagPattern, options: [.caseInsensitive]) {
      cleanedString = tagRegex.stringByReplacingMatches(
        in: cleanedString,
        options: [],
        range: NSRange(cleanedString.startIndex..., in: cleanedString),
        withTemplate: ""
      )
    }

    // 여러 공백을 하나로 줄이고 앞뒤 공백 제거
    return cleanedString
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
