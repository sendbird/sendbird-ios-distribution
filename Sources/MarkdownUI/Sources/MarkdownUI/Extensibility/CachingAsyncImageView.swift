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
  /// Keyed by URL. Cost is the decoded bitmap byte size.
  public static let cache: NSCache<NSURL, UIImage> = {
    let cache = NSCache<NSURL, UIImage>()
    cache.totalCostLimit = 64 * 1024 * 1024
    return cache
  }()

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
      let decoded = await Task.detached(priority: .userInitiated) {
        UIImage(data: data)?.preparingForDisplay()
      }.value
      if let img = decoded {
        Self.cache.setObject(img, forKey: url as NSURL, cost: Self.bitmapByteCost(of: img))
        self.image = img
      } else {
        self.failed = true
      }
    } catch {
      self.failed = true
    }
  }

  private static func bitmapByteCost(of image: UIImage) -> Int {
    let pixels = Int(image.size.width * image.scale) * Int(image.size.height * image.scale)
    return pixels * 4
  }
}
#endif
