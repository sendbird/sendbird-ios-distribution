import CoreGraphics
import Foundation

/// A type that temporarily stores images in memory, keyed by the URL from which they were loaded.
public protocol NetworkImageCache: AnyObject {
  /// Returns the image associated with a given URL.
  func image(for url: URL) -> CGImage?

  /// Sets the image for the specified URL in the cache.
  func setImage(_ image: CGImage, for url: URL)
}

// MARK: - DefaultNetworkImageCache

/// The default network image cache.
public class DefaultNetworkImageCache {
  private enum Constants {
    static let defaultCountLimit = 100
    // 공유 캐시가 붙잡는 디코드된 이미지 바이트 상한. 장 수만으로는 큰 이미지 100장을 막지 못한다.
    static let defaultTotalCostLimit = 64 * 1024 * 1024
  }

  private let cache = NSCache<NSURL, CGImage>()

  /// Creates a default network image cache.
  /// - Parameter countLimit: The maximum number of images that the cache should hold. If `0`,
  ///                         there is no count limit. The default value is `0`.
  public init(countLimit: Int = 0) {
    self.cache.countLimit = countLimit
  }

  convenience init(countLimit: Int, totalCostLimit: Int) {
    self.init(countLimit: countLimit)
    self.cache.totalCostLimit = totalCostLimit
  }

  /// A shared network image cache.
  public static let shared = DefaultNetworkImageCache(
    countLimit: Constants.defaultCountLimit,
    totalCostLimit: Constants.defaultTotalCostLimit
  )
}

extension DefaultNetworkImageCache: NetworkImageCache, @unchecked Sendable {
  public func image(for url: URL) -> CGImage? {
    self.cache.object(forKey: url as NSURL)
  }

  public func setImage(_ image: CGImage, for url: URL) {
    // 디코드된 비트맵 크기를 cost 로 준다. totalCostLimit 이 0 이면 cost 는 쓰이지 않는다.
    self.cache.setObject(image, forKey: url as NSURL, cost: image.bytesPerRow * image.height)
  }
}

extension NetworkImageCache where Self == DefaultNetworkImageCache {
  /// The shared default network image cache.
  static var `default`: Self {
    .shared
  }
}
