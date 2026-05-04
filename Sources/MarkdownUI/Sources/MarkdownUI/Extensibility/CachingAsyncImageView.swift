#if canImport(UIKit) && !os(watchOS)
import Foundation
import SwiftUI
import UIKit

/// An async image view that caches loaded images in memory, keyed by URL.
///
/// Repeated renders of the same URL (for example, a chat cell going off-screen
/// and back on-screen) display the image instantly with no placeholder flash,
/// since the first render after the initial load is served from the cache.
@available(iOS 15.0, tvOS 15.0, *)
public struct CachingAsyncImageView: View {
  /// In-memory cache shared across all `CachingAsyncImageView` instances.
  /// Keyed by URL.
  public static let cache = NSCache<NSURL, UIImage>()

  let url: URL?
  @State private var image: UIImage?
  @State private var failed: Bool = false

  public init(url: URL?) {
    self.url = url
    // Synchronous cache check — if hit, the first render already has the image.
    if let url, let cached = Self.cache.object(forKey: url as NSURL) {
      _image = State(initialValue: cached)
    }
  }

  public var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Color(.secondarySystemBackground)
          .task { await loadImage() }
      }
    }
    .aspectRatio(contentMode: .fill)
  }

  private func loadImage() async {
    guard !failed, let url else { return }
    if let cached = Self.cache.object(forKey: url as NSURL) {
      self.image = cached
      return
    }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      if let img = UIImage(data: data) {
        Self.cache.setObject(img, forKey: url as NSURL)
        self.image = img
      } else {
        self.failed = true
      }
    } catch {
      self.failed = true
    }
  }
}
#endif
