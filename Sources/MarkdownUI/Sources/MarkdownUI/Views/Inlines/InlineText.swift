import SwiftUI
@_weakLinked import _Concurrency

struct InlineText: View {
  @Environment(\.inlineImageProvider) private var inlineImageProvider
  @Environment(\.baseURL) private var baseURL
  @Environment(\.imageBaseURL) private var imageBaseURL
  @Environment(\.softBreakMode) private var softBreakMode
  @Environment(\.theme) private var theme

  @State private var inlineImages: [String: Image] = [:]

  private let inlines: [InlineNode]

  init(_ inlines: [InlineNode]) {
    self.inlines = inlines
  }

  var body: some View {
    TextStyleAttributesReader { attributes in
      if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
        // iOS 15+: 원본 AttributeContainer 사용
        self.inlines.renderText(
          baseURL: self.baseURL,
          textStyles: .init(
            code: self.theme.code,
            emphasis: self.theme.emphasis,
            strong: self.theme.strong,
            strikethrough: self.theme.strikethrough,
            link: self.theme.link
          ),
          images: self.inlineImages,
          softBreakMode: self.softBreakMode,
          attributes: attributes as? AttributeContainer ?? AttributeContainer()
        )
      } else {
        // iOS 14: CompatAttributeContainer 사용
        self.inlines.renderText(
          baseURL: self.baseURL,
          textStyles: .init(
            code: self.theme.code,
            emphasis: self.theme.emphasis,
            strong: self.theme.strong,
            strikethrough: self.theme.strikethrough,
            link: self.theme.link
          ),
          images: self.inlineImages,
          softBreakMode: self.softBreakMode,
          attributes: attributes as? CompatAttributeContainer ?? CompatAttributeContainer()
        )
      }
    }
    .modifier(TaskModifier(inlines: self.inlines) {
      self.inlineImages = await Self.loadInlineImages(
        Set(self.inlines.compactMap(\.imageData)),
        baseURL: self.imageBaseURL,
        provider: self.inlineImageProvider
      )
    })
  }

  /// 이미지마다 실패를 따로 받는다. 하나가 실패해도(예: 크기 상한 초과) 같은 문단의 나머지 이미지는 표시한다.
  static func loadInlineImages(
    _ images: Set<RawImageData>,
    baseURL: URL?,
    provider: InlineImageProvider
  ) async -> [String: Image] {
    guard !images.isEmpty else { return [:] }

    return await withTaskGroup(of: (String, Image)?.self) { taskGroup in
      for image in images {
        guard let url = URL(string: image.source, relativeTo: baseURL) else {
          continue
        }

        taskGroup.addTask {
          guard let loaded = try? await provider.image(with: url, label: image.alt) else {
            return nil
          }
          return (image.source, loaded)
        }
      }

      var inlineImages: [String: Image] = [:]

      for await case let (source, image)? in taskGroup {
        inlineImages[source] = image
      }

      return inlineImages
    }
  }
}

// iOS 버전에 따른 task 모디파이어 처리
private struct TaskModifier<T: Equatable>: ViewModifier {
  let inlines: T
  let action: @Sendable () async -> Void
  
  func body(content: Content) -> some View {
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      // iOS 15+: 네이티브 .task 사용
      content
        .task(id: inlines) {
          await action()
        }
    } else {
      // iOS 14: onAppear + onChange 조합
      content
        .onAppear {
          Task {
            await action()
          }
        }
        .onChange(of: inlines) { _ in
          Task {
            await action()
          }
        }
    }
  }
}