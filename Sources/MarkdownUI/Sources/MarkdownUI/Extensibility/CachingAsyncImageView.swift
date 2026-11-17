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
      // 본문을 메모리 대신 임시 파일로 받아, 큰 파일 주소여도 본문 전체가 메모리에 올라오지 않는다.
      let (file, _) = try await URLSession.shared.download(from: url)
      defer { try? FileManager.default.removeItem(at: file) }
      let decoded = await Task.detached(priority: .userInitiated) {
        Self.decodeImage(at: file)
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

  /// 본문이 상한을 넘으면 그리지 않는다. 넓이가 상한 안이면 기존처럼 원본 크기로,
  /// 넘으면 비율을 지켜 상한 안으로 줄여 디코드한다(원본 크기 비트맵을 만들지 않음).
  nonisolated private static func decodeImage(at file: URL) -> UIImage? {
    // 큰 이미지 하나가 앱을 메모리 부족으로 죽이지 않게 하는 상한.
    // 받은 본문은 20MB 까지, 디코드한 이미지는 2048 x 2048 픽셀(16MB) 넓이까지.
    let maxDataLength = 20 * 1024 * 1024
    let maxPixelCount = 2048 * 2048

    guard
      let length = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
      length <= maxDataLength,
      let source = CGImageSourceCreateWithURL(file as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary)
    else {
      return nil
    }

    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
      let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
      width * height > Double(maxPixelCount)
    else {
      return (try? Data(contentsOf: file)).flatMap { UIImage(data: $0)?.preparingForDisplay() }
    }

    let ratio = (Double(maxPixelCount) / (width * height)).squareRoot()
    guard
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceThumbnailMaxPixelSize: max(1, (max(width, height) * ratio).rounded(.down)),
        ] as CFDictionary
      )
    else {
      return nil
    }
    return UIImage(cgImage: image)
  }

  private static func bitmapByteCost(of image: UIImage) -> Int {
    let pixels = Int(image.size.width * image.scale) * Int(image.size.height * image.scale)
    return pixels * 4
  }
}
#endif
