import Foundation

/// 마크다운 문서 하나에서 그리는 블록 수의 상한.
///
/// `BlockSequence`는 지연 생성 없이 블록마다 뷰를 main에서 한꺼번에 만든다. 시간은 블록 수에 비례해
/// iOS 26.4 시뮬레이터에서 목록 항목 4,000개(16,000자)에 약 1.8초가 걸린다. 같은 줄을 문단 하나로 그리면 0.15초다.
/// 그래서 문서 순서대로 1,000개(목록 항목과 인용, 목록 안의 블록 포함)까지만 그리고 나머지는 그리지 않는다(안내 없음).
enum BlockCountLimit {
  static let maxBlocks = 1_000

  static func limit(_ blocks: [BlockNode]) -> [BlockNode] {
    var remaining = maxBlocks
    return self.limit(blocks, remaining: &remaining)
  }

  private static func limit(_ blocks: [BlockNode], remaining: inout Int) -> [BlockNode] {
    var kept: [BlockNode] = []
    for block in blocks {
      // 자식이 있는 블록은 자식 하나를 함께 그릴 수 있을 때만 남긴다. 빈 인용이나 빈 목록을 그리지 않기 위해서다.
      guard remaining > (block.children.isEmpty ? 0 : 1) else { break }
      remaining -= 1
      switch block {
      case .blockquote(let children):
        kept.append(.blockquote(children: self.limit(children, remaining: &remaining)))
      case .bulletedList(let isTight, let items):
        kept.append(.bulletedList(isTight: isTight, items: self.limit(items, remaining: &remaining)))
      case .numberedList(let isTight, let start, let items):
        kept.append(.numberedList(isTight: isTight, start: start, items: self.limit(items, remaining: &remaining)))
      case .taskList(let isTight, let items):
        let limited = self.limit(items.map { RawListItem(children: $0.children) }, remaining: &remaining)
        kept.append(
          .taskList(
            isTight: isTight,
            items: zip(items, limited).map { RawTaskListItem(isCompleted: $0.isCompleted, children: $1.children) }
          )
        )
      default:
        kept.append(block)
      }
    }
    return kept
  }

  private static func limit(_ items: [RawListItem], remaining: inout Int) -> [RawListItem] {
    var kept: [RawListItem] = []
    for item in items {
      guard remaining > (item.children.isEmpty ? 0 : 1) else { break }
      remaining -= 1
      kept.append(RawListItem(children: self.limit(item.children, remaining: &remaining)))
    }
    return kept
  }
}
