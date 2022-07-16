import EssentialFeed

public final class FeedLoaderWithFallbackComposite: FeedLoader {

    private let primaryLoader: FeedLoader
    private let fallbackLoader: FeedLoader

    public init(primaryLoader: FeedLoader, fallbackLoader: FeedLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        primaryLoader.load { [weak self] primaryResult in
            guard let self = self else {
                return
            }

            switch primaryResult {
            case .success:
                completion(primaryResult)
            case .failure:
                self.fallbackLoader.load { fallbackResult in
                    completion(fallbackResult)
                }
            }
        }
    }

}
