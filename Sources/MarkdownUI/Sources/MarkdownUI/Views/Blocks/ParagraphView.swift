import SwiftUI

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
    
    // 노드 그룹화 - 이미지와 비이미지를 분리하여 연속된 텍스트/링크를 함께 렌더링
    private var groupedContent: [[InlineNode]] {
        var groups: [[InlineNode]] = []
        var currentGroup: [InlineNode] = []
        
        for node in content {
            if case .image = node {
                // 현재 그룹이 있으면 저장
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                    currentGroup = []
                }
                // 이미지는 단독 그룹
                groups.append([node])
            } else {
                // 비이미지 노드는 현재 그룹에 추가
                currentGroup.append(node)
            }
        }
        
        // 마지막 그룹 저장
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    // 혼합 콘텐츠를 별도 렌더링 - 연속된 텍스트/링크는 그룹화하여 함께 렌더링
    @ViewBuilder private var mixedContentView: some View {
        TextStyleAttributesReader { attributes in
            let fontSize = attributes.fontProperties?.scaledSize ?? 17
            let spacing = fontSize * 0.25  // 폰트 크기에 비례한 간격
            
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(groupedContent.enumerated()), id: \.offset) { index, group in
                    if let firstNode = group.first, case .image(let source, let children) = firstNode {
                        CompactImageView(source: source, alt: children.renderPlainText())
                    } else {
                        // 텍스트, 링크 등 연속된 인라인 요소들을 한번에 렌더링
                        InlineText(group)
                    }
                }
            }
        }
    }
}

// 혼합 콘텐츠 전용 이미지 뷰 - ImageView와 동일한 방식으로 렌더링 (테마 적용)
private struct CompactImageView: View {
    @Environment(\.theme.image) private var image
    @Environment(\.imageProvider) private var imageProvider
    @Environment(\.imageBaseURL) private var baseURL
    
    let source: String
    let alt: String
    
    var body: some View {
        self.image.makeBody(
            configuration: .init(
                label: .init(self.label),
                content: .init(block: .paragraph(content: [.image(source: source, children: [.text(alt)])]))
            )
        )
    }
    
    @ViewBuilder private var label: some View {
        if let url = URL(string: source, relativeTo: baseURL) {
            imageProvider.makeImage(url: url)
                .accessibilityLabel(alt)
        }
    }
}
