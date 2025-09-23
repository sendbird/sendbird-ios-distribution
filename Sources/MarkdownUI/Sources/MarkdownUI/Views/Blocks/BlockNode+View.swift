import SwiftUI

extension BlockNode: View {

  // Helper function to safely create NSRegularExpression
  private func safeRegex(pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
    do {
      return try NSRegularExpression(pattern: pattern, options: options)
    } catch {
      print("BlockNode: Failed to create regex pattern '\(pattern)': \(error)")
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

  private func isHTMLTable(_ html: String) -> Bool {
    html.lowercased().contains("<table")
  }

  private func isHTMLList(_ html: String) -> Bool {
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

  private func parseHTMLList(_ html: String) -> some View {
    let isOrdered = html.lowercased().contains("<ol")
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

  private func extractTableData(from html: String) -> (alignments: [RawTableColumnAlignment], rows: [RawTableRow]) {
    let cleanedHTML = html
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

    let headerPattern = "<thead[^>]*>.*?<tr[^>]*>(.*?)</tr>.*?</thead>"
    guard let headerRegex = safeRegex(pattern: headerPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return (alignments: [RawTableColumnAlignment.none], rows: [])
    }

    let bodyPattern = "<tbody[^>]*>(.*?)</tbody>"
    guard let bodyRegex = safeRegex(pattern: bodyPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return (alignments: [RawTableColumnAlignment.none], rows: [])
    }

    var rows: [RawTableRow] = []
    var columnCount = 0

    if let headerMatch = headerRegex.firstMatch(in: cleanedHTML, range: NSRange(cleanedHTML.startIndex..., in: cleanedHTML)),
       let headerRange = Range(headerMatch.range(at: 1), in: cleanedHTML) {
      let headerContent = String(cleanedHTML[headerRange])
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
    return (alignments: alignments, rows: rows)
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

  private func extractListItems(from html: String) -> [RawListItem] {
    let itemPattern = "<li[^>]*>(.*?)</li>"
    guard let regex = safeRegex(pattern: itemPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return []
    }
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

    return matches.compactMap { match in
      guard let range = Range(match.range(at: 1), in: html) else { return nil }
      let itemContent = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)

      // li 태그의 직접적인 텍스트 내용만 추출 (중첩된 리스트 제외)
      let directText = extractDirectTextOnly(from: itemContent)
      let paragraph = BlockNode.paragraph(content: [.text(directText)])
      return RawListItem(children: [paragraph])
    }
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
