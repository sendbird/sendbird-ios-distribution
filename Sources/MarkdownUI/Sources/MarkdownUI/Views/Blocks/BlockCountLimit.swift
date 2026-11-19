import Foundation

/// 마크다운 문서 하나에서 그리는 블록 수의 상한.
///
/// `BlockSequence`는 지연 생성 없이 블록마다 뷰를 main에서 한꺼번에 만든다. 시간은 블록 수에 비례해
/// iOS 26.4 시뮬레이터에서 목록 항목 4,000개(16,000자)에 약 2.8초가 걸린다. 같은 줄을 문단 하나로 그리면 0.15초다.
/// 그래서 문서 순서대로 1,000개까지만 그리고, 처음 들어가지 못한 블록부터 뒤는 모두 그리지 않는다(안내 없음).
/// 목록 항목, 인용과 목록 안의 블록, HTML 목록(`<ul>`, `<ol>`)의 항목도 하나씩 센다.
enum BlockCountLimit {
  static let maxBlocks = 1_000

  /// 남은 개수와, 들어가지 못한 블록을 이미 만났는지. 만났으면 바깥 목록이나 인용도 그 자리에서 멈춘다.
  private struct Budget {
    var remaining: Int
    var isExhausted = false
  }

  static func limit(_ blocks: [BlockNode]) -> [BlockNode] {
    var budget = Budget(remaining: maxBlocks)
    return self.limit(blocks, budget: &budget)
  }

  private static func limit(_ blocks: [BlockNode], budget: inout Budget) -> [BlockNode] {
    var kept: [BlockNode] = []
    for block in blocks {
      guard !budget.isExhausted else { break }
      guard let limited = self.limit(block, budget: &budget) else {
        budget.isExhausted = true
        break
      }
      kept.append(limited)
    }
    return kept
  }

  /// 블록 하나를 남길 수 있으면 상한 안으로 줄인 값을, 없으면 nil 을 돌려준다.
  /// 자식이 있는 블록은 자식을 하나도 남기지 못하면 nil 이다. 빈 인용이나 빈 목록을 그리지 않기 위해서다.
  private static func limit(_ block: BlockNode, budget: inout Budget) -> BlockNode? {
    guard budget.remaining > 0 else { return nil }
    var inner = Budget(remaining: budget.remaining - 1)
    let result: BlockNode?
    switch block {
    case .blockquote(let children):
      let kept = self.limit(children, budget: &inner)
      result = kept.isEmpty && !children.isEmpty ? nil : .blockquote(children: kept)
    case .bulletedList(let isTight, let items):
      let kept = self.limit(items, budget: &inner)
      result = kept.isEmpty && !items.isEmpty ? nil : .bulletedList(isTight: isTight, items: kept)
    case .numberedList(let isTight, let start, let items):
      let kept = self.limit(items, budget: &inner)
      result = kept.isEmpty && !items.isEmpty ? nil : .numberedList(isTight: isTight, start: start, items: kept)
    case .taskList(let isTight, let items):
      var kept: [RawTaskListItem] = []
      for item in items {
        guard !inner.isExhausted else { break }
        guard let children = self.limitItem(item.children, budget: &inner) else {
          inner.isExhausted = true
          break
        }
        kept.append(RawTaskListItem(isCompleted: item.isCompleted, children: children))
      }
      result = kept.isEmpty && !items.isEmpty ? nil : .taskList(isTight: isTight, items: kept)
    case .htmlBlock(let content) where !block.isHTMLTable(content) && block.isHTMLList(content):
      result = self.limitHTMLList(block, content: content, budget: &inner)
    case .htmlBlock(let content)
    where !block.isHTMLTable(content) && !block.isHTMLHeading(content) && !block.isHTMLCode(content)
      && block.isHTMLBlockquote(content):
      // 뷰는 HTML 인용문을 인용 뷰와 그 안의 문단 뷰 하나로 그린다(분기 순서도 뷰와 같다).
      guard inner.remaining > 0 else { return nil }
      inner.remaining -= 1
      result = block
    default:
      result = block
    }
    guard result != nil else { return nil }
    budget = inner
    return result
  }

  /// 뷰는 HTML 목록의 `<li>`마다 항목 뷰와 문단 뷰를 만든다. 뷰와 같은 스캔(`listItemContents`)으로 항목 수를 세어,
  /// 남은 개수 안이면 그대로 두고 그 수만큼만 뺀다. 넘치면 뷰와 같은 방식으로 항목을 뽑아 앞부분만 목록으로 남긴다.
  /// 이때는 뷰가 HTML을 다시 훑지 않도록 뷰가 그리는 것과 같은 목록 블록으로 바꾼다.
  private static func limitHTMLList(_ block: BlockNode, content: String, budget: inout Budget) -> BlockNode? {
    let itemCount = BlockNode.listItemContents(in: content).count
    if itemCount * 2 <= budget.remaining {
      budget.remaining -= itemCount * 2
      return block
    }
    let items = block.extractListItems(from: content)
    let kept = self.limit(items, budget: &budget)
    if kept.isEmpty && !items.isEmpty {
      return nil
    }
    return block.isHTMLOrderedList(content)
      ? .numberedList(isTight: true, start: 1, items: kept)
      : .bulletedList(isTight: true, items: kept)
  }

  private static func limit(_ items: [RawListItem], budget: inout Budget) -> [RawListItem] {
    var kept: [RawListItem] = []
    for item in items {
      guard !budget.isExhausted else { break }
      guard let children = self.limitItem(item.children, budget: &budget) else {
        budget.isExhausted = true
        break
      }
      kept.append(RawListItem(children: children))
    }
    return kept
  }

  /// 목록 항목 하나: 항목 자체로 1개, 그 안의 블록을 하나씩 센다.
  private static func limitItem(_ children: [BlockNode], budget: inout Budget) -> [BlockNode]? {
    guard budget.remaining > 0 else { return nil }
    var inner = Budget(remaining: budget.remaining - 1)
    let kept = self.limit(children, budget: &inner)
    guard !(kept.isEmpty && !children.isEmpty) else { return nil }
    budget = inner
    return kept
  }
}
