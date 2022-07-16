import EssentialFeed
import Foundation

public final class FeedImageLoaderWithFallbackComposite: FeedImageDataLoader {

    private let primaryLoader: FeedImageDataLoader
    private let fallbackLoader: FeedImageDataLoader

    public init(primaryLoader: FeedImageDataLoader, fallbackLoader: FeedImageDataLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    private class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?

        func cancel() {
            wrapped?.cancel()
        }
    }

    public func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        let taskWrapper = TaskWrapper()
        taskWrapper.wrapped = primaryLoader.loadImageData(from: url) { [weak self] primaryResult in
            guard let self = self else {
                return
            }
            switch primaryResult {
            case .success:
                completion(primaryResult)

            case .failure:
                taskWrapper.wrapped = self.fallbackLoader.loadImageData(from: url, completion: completion)
            }
        }
        return taskWrapper
    }
    
    public func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        primaryLoader.save(data, for: url, completion: completion)
    }
    
}
