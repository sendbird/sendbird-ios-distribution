@_weakLinked import _Concurrency
import CoreGraphics
import Foundation
import ImageIO

/// A type that loads and caches images.
public protocol NetworkImageLoader: AnyObject, Sendable {
  /// Loads and returns the image from a given URL.
  func image(from url: URL) async throws -> CGImage
}

// MARK: - DefaultNetworkImageLoader

/// The default network image loader.
public actor DefaultNetworkImageLoader {
  private enum Constants {
    static let memoryCapacity = 10 * 1024 * 1024
    static let diskCapacity = 100 * 1024 * 1024
    static let timeoutInterval: TimeInterval = 15
    // 큰 이미지 하나가 앱을 메모리 부족으로 죽이지 않게 하는 상한.
    // 받은 본문은 20MB 까지, 디코드한 이미지는 2048 x 2048 픽셀(16MB) 넓이까지.
    static let maxDataLength = 20 * 1024 * 1024
    static let maxPixelCount = 2048 * 2048
  }

  private let data: (URL) async throws -> (Data, URLResponse)
  private let cache: NetworkImageCache

  private var ongoingTasks: [URL: Task<CGImage, Error>] = [:]

  /// Creates a default network image cache.
  /// - Parameter countLimit: The maximum number of images that the cache should hold. If `0`,
  ///                         there is no count limit. The default value is `0`.

  /// Creates a default network image loader.
  /// - Parameters:
  ///   - cache: The network image cache that this loader will use to store the images.
  ///   - session: The session that this loader will use to fetch the images.
  public init(cache: NetworkImageCache, session: URLSession) {
    self.init(cache: cache, data: session.data(from:))
  }

  /// A shared network image loader.
  public static let shared = DefaultNetworkImageLoader(
    cache: .default,
    session: .imageLoading(
      memoryCapacity: Constants.memoryCapacity,
      diskCapacity: Constants.diskCapacity,
      timeoutInterval: Constants.timeoutInterval
    )
  )

  init(
    cache: NetworkImageCache,
    data: @escaping (URL) async throws -> (Data, URLResponse)
  ) {
    self.data = data
    self.cache = cache
  }
}

extension DefaultNetworkImageLoader: NetworkImageLoader {
  public func image(from url: URL) async throws -> CGImage {
    if let image = self.cache.image(for: url) {
      return image
    }

    if let task = self.ongoingTasks[url] {
      return try await task.value
    }

    let task = Task<CGImage, Error> {
      let (data, response) = try await self.data(url)

      // remove ongoing task
      self.ongoingTasks.removeValue(forKey: url)

      guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
        200..<300 ~= statusCode
      else {
        throw URLError(.badServerResponse)
      }

      // 상한을 넘는 본문은 디코드하지 않는다.
      guard data.count <= Constants.maxDataLength else {
        throw URLError(.dataLengthExceedsMaximum)
      }

      guard
        let source = CGImageSourceCreateWithData(data as CFData, nil),
        let image = Self.decodeImage(from: source)
      else {
        throw URLError(.cannotDecodeContentData)
      }

      // add image to cache
      self.cache.setImage(image, for: url)

      return image
    }

    // add ongoing task
    self.ongoingTasks[url] = task

    return try await task.value
  }
}

extension DefaultNetworkImageLoader {
  /// 넓이가 상한 안이면 원본 크기로, 넘으면 비율을 지켜 상한 안으로 줄여 디코드한다.
  /// 원본 크기 비트맵을 만들지 않도록 ImageIO 썸네일 API 로 바로 줄인다.
  private static func decodeImage(from source: CGImageSource) -> CGImage? {
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
      let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
      width * height > Double(Constants.maxPixelCount)
    else {
      return CGImageSourceCreateImageAtIndex(
        source, 0,
        [kCGImageSourceShouldCache: true] as CFDictionary
      )
    }

    let ratio = (Double(Constants.maxPixelCount) / (width * height)).squareRoot()
    return CGImageSourceCreateThumbnailAtIndex(
      source, 0,
      [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(1, (max(width, height) * ratio).rounded(.down)),
      ] as CFDictionary
    )
  }
}

extension NetworkImageLoader where Self == DefaultNetworkImageLoader {
  /// The shared default network image loader.
  public static var `default`: Self {
    .shared
  }
}
