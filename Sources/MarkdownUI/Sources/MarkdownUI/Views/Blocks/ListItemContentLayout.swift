import SwiftUI

extension View {
  // 목록 항목의 Label 은 내용 크기를 여러 높이로 시험 삼아 재고, 그 결과가 안쪽 목록에 새 제안으로 내려가
  // 단계마다 측정 횟수가 곱해진다. `- ` 를 18번 겹친 37자가 6초 넘게 main 스레드를 잡았다.
  // 항목 내용은 너비가 정해지면 높이가 정해지므로, 너비만 넘겨 너비마다 한 번만 잰다.
  // iOS 16 미만은 Layout 이 없어 그대로 둔다.
  @ViewBuilder
  func measuredOncePerWidth() -> some View {
    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      ListItemContentLayout { self }
    } else {
      self
    }
  }
}

// 하위 뷰 하나를 그대로 놓는다. 높이 제안은 넘기지 않고, 잰 결과는 너비마다 기억한다.
// 하위 뷰가 바뀌면 SwiftUI 가 updateCache 를 불러 기억한 값을 비운다.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct ListItemContentLayout: Layout {
  typealias Cache = [CGFloat?: ViewDimensions]

  func makeCache(subviews: Subviews) -> Cache {
    [:]
  }

  func updateCache(_ cache: inout Cache, subviews: Subviews) {
    cache.removeAll()
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
    guard let dimensions = self.dimensions(proposal, subviews, &cache) else {
      return .zero
    }
    return CGSize(width: dimensions.width, height: dimensions.height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
    subviews.first?.place(
      at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: proposal.width, height: nil)
    )
  }

  func explicitAlignment(
    of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
    cache: inout Cache
  ) -> CGFloat? {
    self.dimensions(proposal, subviews, &cache)?[explicit: guide].map { bounds.minX + $0 }
  }

  func explicitAlignment(
    of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
    cache: inout Cache
  ) -> CGFloat? {
    self.dimensions(proposal, subviews, &cache)?[explicit: guide].map { bounds.minY + $0 }
  }

  private func dimensions(_ proposal: ProposedViewSize, _ subviews: Subviews, _ cache: inout Cache) -> ViewDimensions? {
    guard let subview = subviews.first else {
      return nil
    }
    if let cached = cache[proposal.width] {
      return cached
    }
    let dimensions = subview.dimensions(in: ProposedViewSize(width: proposal.width, height: nil))
    cache[proposal.width] = dimensions
    return dimensions
  }
}
