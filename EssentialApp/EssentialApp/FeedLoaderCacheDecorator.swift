import EssentialFeed

public final class FeedLoaderCacheDecorator: FeedLoader {

    private let decoratee: FeedLoader
    private let cache: FeedCache

    public init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
        decoratee.load { [weak self] loadResult in
            completion(loadResult.map { feed in
                self?.cache.saveIgnoringResult(feed)
                return feed
            })
        }
    }

}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        self.save(feed) { _ in }
    }
}
