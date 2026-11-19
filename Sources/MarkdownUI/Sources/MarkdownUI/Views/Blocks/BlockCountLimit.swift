import Foundation

/// 마크다운 문서 하나에서 그리는 블록 수의 상한.
///
/// `BlockSequence`는 지연 생성 없이 블록마다 뷰를 main에서 한꺼번에 만든다. 시간은 블록 수에 비례해
/// iOS 26.4 시뮬레이터에서 목록 항목 4,000개(16,000자)에 약 2.8초가 걸린다. 같은 줄을 문단 하나로 그리면 0.15초다.
/// 그래서 문서 순서대로 1,000개까지만 그리고 나머지는 그리지 않는다(안내 없음).
/// 목록 항목, 인용과 목록 안의 블록, HTML 목록(`<ul>`, `<ol>`)의 항목도 하나씩 센다.
enum BlockCountLimit {
  static let maxBlocks = 1_000

  static func limit(_ blocks: [BlockNode]) -> [BlockNode] {
    var remaining = maxBlocks
    return self.limit(blocks, remaining: &remaining)
  }

  /// 앞에서부터 들어가는 블록까지만 남긴다. 들어가지 못한 블록을 만나면 그 뒤는 모두 버린다.
  private static func limit(_ blocks: [BlockNode], remaining: inout Int) -> [BlockNode] {
    var kept: [BlockNode] = []
    for block in blocks {
      guard let limited = self.limit(block, remaining: &remaining) else { break }
      kept.append(limited)
    }
    return kept
  }

  /// 블록 하나를 남길 수 있으면 상한 안으로 줄인 값을, 없으면 nil 을 돌려준다.
  /// 자식이 있는 블록은 자식을 하나도 남기지 못하면 nil 이다. 빈 인용이나 빈 목록을 그리지 않기 위해서다.
  private static func limit(_ block: BlockNode, remaining: inout Int) -> BlockNode? {
    guard remaining > 0 else { return nil }
    var left = remaining - 1
    let result: BlockNode?
    switch block {
    case .blockquote(let children):
      let kept = self.limit(children, remaining: &left)
      result = kept.isEmpty && !children.isEmpty ? nil : .blockquote(children: kept)
    case .bulletedList(let isTight, let items):
      let kept = self.limit(items, remaining: &left)
      result = kept.isEmpty && !items.isEmpty ? nil : .bulletedList(isTight: isTight, items: kept)
    case .numberedList(let isTight, let start, let items):
      let kept = self.limit(items, remaining: &left)
      result = kept.isEmpty && !items.isEmpty ? nil : .numberedList(isTight: isTight, start: start, items: kept)
    case .taskList(let isTight, let items):
      var kept: [RawTaskListItem] = []
      for item in items {
        guard let children = self.limitItem(item.children, remaining: &left) else { break }
        kept.append(RawTaskListItem(isCompleted: item.isCompleted, children: children))
      }
      result = kept.isEmpty && !items.isEmpty ? nil : .taskList(isTight: isTight, items: kept)
    case .htmlBlock(let content) where !block.isHTMLTable(content) && block.isHTMLList(content):
      // 뷰는 HTML 목록의 항목마다 뷰를 만든다. 다 들어가면 그대로 두고, 넘치면 뷰가 그리는 것과 같은 목록으로 바꿔 줄인다.
      let items = block.extractListItems(from: content)
      let ordered = block.isHTMLOrderedList(content)
      var probe = left
      let kept = self.limit(items, remaining: &probe)
      if kept.count == items.count {
        result = block
      } else if kept.isEmpty {
        result = nil
      } else {
        result = ordered ? .numberedList(isTight: true, start: 1, items: kept) : .bulletedList(isTight: true, items: kept)
      }
      left = probe
    default:
      result = block
    }
    if result != nil {
      remaining = left
    }
    return result
  }

  private static func limit(_ items: [RawListItem], remaining: inout Int) -> [RawListItem] {
    var kept: [RawListItem] = []
    for item in items {
      guard let children = self.limitItem(item.children, remaining: &remaining) else { break }
      kept.append(RawListItem(children: children))
    }
    return kept
  }

  /// 목록 항목 하나: 항목 자체로 1개, 그 안의 블록을 하나씩 센다.
  private static func limitItem(_ children: [BlockNode], remaining: inout Int) -> [BlockNode]? {
    guard remaining > 0 else { return nil }
    var left = remaining - 1
    let kept = self.limit(children, remaining: &left)
    guard !(kept.isEmpty && !children.isEmpty) else { return nil }
    remaining = left
    return kept
  }
}
