import Foundation

// MARK: - iOS 15+ 원본 구현
#if canImport(SwiftUI) && compiler(>=5.5)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) -> AttributedString {
    var renderer = ModernAttributedStringInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      softBreakMode: softBreakMode,
      attributes: attributes
    )
    renderer.render(self)
    return renderer.result.resolvingFonts()
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ModernAttributedStringInlineRenderer {
  var result = AttributedString()

  private let baseURL: URL?
  private let textStyles: InlineTextStyles
  private let softBreakMode: SoftBreak.Mode
  private var attributes: AttributeContainer
  private var shouldSkipNextWhitespace = false

  init(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) {
    self.baseURL = baseURL
    self.textStyles = textStyles
    self.softBreakMode = softBreakMode
    self.attributes = attributes
  }

  mutating func render(_ inline: InlineNode) {
    switch inline {
    case .text(let content):
      self.renderText(content)
    case .softBreak:
      self.renderSoftBreak()
    case .lineBreak:
      self.renderLineBreak()
    case .code(let content):
      self.renderCode(content)
    case .html(let content):
      self.renderHTML(content)
    case .emphasis(let children):
      self.renderEmphasis(children: children)
    case .strong(let children):
      self.renderStrong(children: children)
    case .strikethrough(let children):
      self.renderStrikethrough(children: children)
    case .link(let destination, let children):
      self.renderLink(destination: destination, children: children)
    case .image(let source, let children):
      self.renderImage(source: source, children: children)
    }
  }

  private mutating func renderText(_ text: String) {
    var text = text

    if self.shouldSkipNextWhitespace {
      self.shouldSkipNextWhitespace = false
      text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }

    self.result += .init(text, attributes: self.attributes)
  }

  private mutating func renderSoftBreak() {
    switch softBreakMode {
    case .space where self.shouldSkipNextWhitespace:
      self.shouldSkipNextWhitespace = false
    case .space:
      self.result += .init(" ", attributes: self.attributes)
    case .lineBreak:
      self.renderLineBreak()
    }
  }

  private mutating func renderLineBreak() {
    self.result += .init("\n", attributes: self.attributes)
  }

  private mutating func renderCode(_ code: String) {
    self.result += .init(code, attributes: self.textStyles.code.mergingAttributes(self.attributes))
  }

  private mutating func renderHTML(_ html: String) {
    let tag = HTMLTag(html)

    switch tag?.name.lowercased() {
    case "br":
      self.renderLineBreak()
      self.shouldSkipNextWhitespace = true
    default:
      self.renderText(html)
    }
  }

  private mutating func renderEmphasis(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.emphasis.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrong(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strong.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrikethrough(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strikethrough.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderLink(destination: String, children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.link.mergingAttributes(self.attributes)
    self.attributes.link = URL(string: destination, relativeTo: self.baseURL)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderImage(source: String, children: [InlineNode]) {
    // AttributedString does not support images
  }
}
#endif

// MARK: - iOS 14 호환 구현
extension InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: CompatAttributeContainer
  ) -> CompatAttributedString {
    var renderer = AttributedStringInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      softBreakMode: softBreakMode,
      attributes: attributes
    )
    renderer.render(self)
    return renderer.result.resolvingFonts()
  }
}

private struct AttributedStringInlineRenderer {
  var result = CompatAttributedString("")

  private let baseURL: URL?
  private let textStyles: InlineTextStyles
  private let softBreakMode: SoftBreak.Mode
  private var attributes: CompatAttributeContainer
  private var shouldSkipNextWhitespace = false

  init(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: CompatAttributeContainer
  ) {
    self.baseURL = baseURL
    self.textStyles = textStyles
    self.softBreakMode = softBreakMode
    self.attributes = attributes
  }

  mutating func render(_ inline: InlineNode) {
    switch inline {
    case .text(let content):
      self.renderText(content)
    case .softBreak:
      self.renderSoftBreak()
    case .lineBreak:
      self.renderLineBreak()
    case .code(let content):
      self.renderCode(content)
    case .html(let content):
      self.renderHTML(content)
    case .emphasis(let children):
      self.renderEmphasis(children: children)
    case .strong(let children):
      self.renderStrong(children: children)
    case .strikethrough(let children):
      self.renderStrikethrough(children: children)
    case .link(let destination, let children):
      self.renderLink(destination: destination, children: children)
    case .image(let source, let children):
      self.renderImage(source: source, children: children)
    }
  }

  private mutating func renderText(_ text: String) {
    var text = text

    if self.shouldSkipNextWhitespace {
      self.shouldSkipNextWhitespace = false
      text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }

    self.result += CompatAttributedString(text, attributes: self.attributes)
  }

  private mutating func renderSoftBreak() {
    switch softBreakMode {
    case .space where self.shouldSkipNextWhitespace:
      self.shouldSkipNextWhitespace = false
    case .space:
      self.result += CompatAttributedString(" ", attributes: self.attributes)
    case .lineBreak:
      self.renderLineBreak()
    }
  }

  private mutating func renderLineBreak() {
    self.result += CompatAttributedString("\n", attributes: self.attributes)
  }

  private mutating func renderCode(_ code: String) {
    self.result += CompatAttributedString(code, attributes: self.textStyles.code.mergingAttributes(self.attributes))
  }

  private mutating func renderHTML(_ html: String) {
    let tag = HTMLTag(html)

    switch tag?.name.lowercased() {
    case "br":
      self.renderLineBreak()
      self.shouldSkipNextWhitespace = true
    default:
      self.renderText(html)
    }
  }

  private mutating func renderEmphasis(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.emphasis.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrong(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strong.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrikethrough(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strikethrough.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderLink(destination: String, children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.link.mergingAttributes(self.attributes)
    self.attributes.link = URL(string: destination, relativeTo: self.baseURL)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderImage(source: String, children: [InlineNode]) {
    // AttributedString does not support images
  }
}

// MARK: - 공통 Extensions
extension TextStyle {
  fileprivate func mergingAttributes(_ attributes: CompatAttributeContainer) -> CompatAttributeContainer {
    var newAttributes = attributes
    self._collectAttributes(in: &newAttributes)
    return newAttributes
  }
  
  #if canImport(SwiftUI) && compiler(>=5.5)
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  fileprivate func mergingAttributes(_ attributes: AttributeContainer) -> AttributeContainer {
    var newAttributes = attributes
    self._collectAttributes(in: &newAttributes)
    return newAttributes
  }
  #endif
}