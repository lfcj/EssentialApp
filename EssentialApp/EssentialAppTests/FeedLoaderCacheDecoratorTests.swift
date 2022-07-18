import EssentialFeed
import XCTest

final class FeedLoaderCacheDecorator: FeedLoader {

    private let decoratee: FeedLoader

    init(decoratee: FeedLoader) {
        self.decoratee = decoratee
    }

    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
        decoratee.load(completion: completion)
    }

}

final class FeedLoaderCacheDecoratorTests: XCTestCase {

    func test_load_deliversFeedOnLoaderSuccess() {
        let feed = uniqueFeed()
        let loader = FeedLoaderStub(result: .success(feed))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)

        expect(sut, toCompleteWith: .success(feed))
    }

    func test_load_deliversErrorOnLoaderFailure() {
        let error = anyError()
        let loader = FeedLoaderStub(result: .failure(error))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)

        expect(sut, toCompleteWith: .failure(error))
    }

}

// MARK: - Helpers

private extension FeedLoaderCacheDecoratorTests {}
