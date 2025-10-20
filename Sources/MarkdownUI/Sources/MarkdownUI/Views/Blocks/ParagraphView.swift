import SwiftUI
import SendbirdNetworkImage

struct ParagraphView: View {
  @Environment(\.theme.paragraph) private var paragraph

  private let content: [InlineNode]

  init(content: String) {
    self.init(
      content: [
        .text(content.hasSuffix("\n") ? String(content.dropLast()) : content)
      ]
    )
  }

  init(content: [InlineNode]) {
    self.content = content
  }

  var body: some View {
    self.paragraph.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: .paragraph(content: self.content))
      )
    )
  }

  @ViewBuilder private var label: some View {
    if let imageView = ImageView(content) {
      imageView
    } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
      let imageFlow = ImageFlow(content)
    {
      imageFlow
    } else if hasMixedImageContent {
      // 이미지와 다른 요소가 혼합된 경우
      mixedContentView
    } else {
      InlineText(content)
    }
  }

  // 혼합 콘텐츠 감지
  private var hasMixedImageContent: Bool {
    let hasImage = content.contains { node in
      if case .image = node { return true }
      return false
    }
    return hasImage && content.count > 1
  }

  // 혼합 콘텐츠를 별도 렌더링 (마진 없음)
  @ViewBuilder private var mixedContentView: some View {
    TextStyleAttributesReader { attributes in
      let fontSize = attributes.fontProperties?.scaledSize ?? 17  // 기본 폰트 크기
      let negativeMargin = -fontSize * 0.6  // 폰트 크기의 60%

      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(content.enumerated()), id: \.offset) { index, node in
          Group {
            switch node {
            case .image(let source, let children):
              // ImageView 대신 직접 이미지 로드
              CompactImageView(source: source, alt: children.renderPlainText())
            default:
              InlineText([node])
            }
          }
          .padding(.top, index > 0 ? negativeMargin : 0)  // 폰트 크기에 비례한 negative margin
        }
      }
    }
  }
}

// 혼합 콘텐츠 전용 간결한 이미지 뷰 (ResizeToFit 우회)
private struct CompactImageView: View {
  @Environment(\.imageBaseURL) private var baseURL

  let source: String
  let alt: String

  var body: some View {
    if let url = url {
      // SendbirdNetworkImage를 직접 사용하여 ResizeToFit 우회
      SendbirdNetworkImage.NetworkImage(url: url) { state in
        switch state {
        case .empty, .failure:
          Color.clear.frame(height: 0)
        case .success(let image, _):
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
      }
      .accessibilityLabel(alt)
    }
  }

  private var url: URL? {
    URL(string: source, relativeTo: baseURL)
  }
}
