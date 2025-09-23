import Foundation

struct HTMLTag {
  let name: String
}

extension HTMLTag {
  private enum Constants {
    static let tagExpression: NSRegularExpression = {
      do {
        return try NSRegularExpression(pattern: "<\\/?([a-zA-Z0-9]+)[^>]*>")
      } catch {
        debugPrint("HTMLTag: Failed to create regex pattern: \(error)")
        return NSRegularExpression()
      }
    }()
  }

  init?(_ description: String) {
    guard
      let match = Constants.tagExpression.firstMatch(
        in: description,
        range: NSRange(description.startIndex..., in: description)
      ),
      let nameRange = Range(match.range(at: 1), in: description)
    else {
      return nil
    }

    self.name = String(description[nameRange])
  }
}
