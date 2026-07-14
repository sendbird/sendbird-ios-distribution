import Foundation

enum MarkdownSyntaxBlocklist {
  static func process(_ markdown: String) -> String {
    guard !markdown.isEmpty else { return markdown }

    var result = ""
    result.reserveCapacity(markdown.utf8.count)
    var activeFence: Fence?

    markdown.enumerateSubstrings(
      in: markdown.startIndex..<markdown.endIndex,
      options: [.byLines, .substringNotRequired]
    ) { _, lineRange, enclosingRange, _ in
      let line = markdown[lineRange]

      if let fence = activeFence {
        result.append(contentsOf: line)
        if isClosingFence(line, for: fence) {
          activeFence = nil
        }
      } else if let fence = openingFence(in: line) {
        activeFence = fence
        result.append(contentsOf: line)
      } else {
        result.append(contentsOf: neutralizingReferenceDefinition(in: line))
      }

      result.append(contentsOf: markdown[lineRange.upperBound..<enclosingRange.upperBound])
    }

    return result
  }
}

private extension MarkdownSyntaxBlocklist {
  struct Fence {
    let marker: Character
    let length: Int
  }

  struct FenceRun {
    let marker: Character
    let length: Int
    let remainder: Substring
  }

  static func openingFence(in line: Substring) -> Fence? {
    guard let run = fenceRun(in: line) else { return nil }
    if run.marker == "`", run.remainder.contains("`") {
      return nil
    }
    return Fence(marker: run.marker, length: run.length)
  }

  static func isClosingFence(_ line: Substring, for fence: Fence) -> Bool {
    guard let run = fenceRun(in: line),
          run.marker == fence.marker,
          run.length >= fence.length else {
      return false
    }
    return run.remainder.allSatisfy { $0 == " " || $0 == "\t" }
  }

  static func fenceRun(in line: Substring) -> FenceRun? {
    guard let contentStart = contentStart(in: line) else { return nil }
    let marker = line[contentStart]
    guard marker == "`" || marker == "~" else { return nil }

    var markerEnd = contentStart
    var length = 0
    while markerEnd < line.endIndex, line[markerEnd] == marker {
      length += 1
      markerEnd = line.index(after: markerEnd)
    }
    guard length >= 3 else { return nil }

    return FenceRun(marker: marker, length: length, remainder: line[markerEnd...])
  }

  static func neutralizingReferenceDefinition(in line: Substring) -> String {
    guard let opener = referenceDefinitionOpener(in: line) else {
      return String(line)
    }

    var result = String(line[..<opener])
    result.append("\\")
    result.append(contentsOf: line[opener...])
    return result
  }

  static func referenceDefinitionOpener(in line: Substring) -> Substring.Index? {
    guard let opener = contentStart(in: line), line[opener] == "[" else {
      return nil
    }

    var index = line.index(after: opener)
    guard index < line.endIndex else { return nil }

    var labelLength = 0
    var isEscaped = false
    while index < line.endIndex {
      let character = line[index]

      if isEscaped {
        isEscaped = false
        labelLength += 1
      } else if character == "\\" {
        isEscaped = true
        labelLength += 1
      } else if character == "[" {
        return nil
      } else if character == "]" {
        let colon = line.index(after: index)
        guard labelLength > 0,
              labelLength <= 999,
              colon < line.endIndex,
              line[colon] == ":" else {
          return nil
        }
        return opener
      } else {
        labelLength += 1
      }

      index = line.index(after: index)
    }

    return nil
  }

  static func contentStart(in line: Substring) -> Substring.Index? {
    var index = line.startIndex
    var indentation = 0
    while index < line.endIndex, line[index] == " " {
      indentation += 1
      guard indentation <= 3 else { return nil }
      index = line.index(after: index)
    }
    return index < line.endIndex ? index : nil
  }
}
