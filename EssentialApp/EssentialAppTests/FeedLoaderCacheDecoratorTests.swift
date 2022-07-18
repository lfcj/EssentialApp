import EssentialFeed
import XCTest

protocol FeedCache {
    typealias SaveResult = Result<Void, Error>
    typealias SaveCompletion = (SaveResult) -> Void
    func save(_ feed: [FeedImage], completion: @escaping SaveCompletion)
}

final class FeedLoaderCacheDecorator: FeedLoader {

    private let decoratee: FeedLoader
    private let cache: FeedCache

    init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
        decoratee.load { [weak self] loadResult in
            switch loadResult {
            case .success(let feed):
                self?.cache.save(feed) { cacheResult in completion(loadResult) }
            case .failure:
                completion(loadResult)
            }
        }
    }

}

final class FeedLoaderCacheDecoratorTests: XCTestCase, FeedLoaderTestCase {

    func test_load_deliversFeedOnLoaderSuccess() {
        let feed = uniqueFeed()
        let sut = makeSUT(loaderResult: .success(feed))

        expect(sut, toCompleteWith: .success(feed))
    }

    func test_load_deliversErrorOnLoaderFailure() {
        let error = anyError()
        let sut = makeSUT(loaderResult: .failure(error))

        expect(sut, toCompleteWith: .failure(error))
    }

    func test_load_cachesLoadedFeedOnLoaderSuccess() {
        let feed = uniqueFeed()
        let cache = CacheSpy()
        let sut = makeSUT(loaderResult: .success(feed), cache: cache)

        sut.load { _ in }

        XCTAssertEqual(cache.messages, [.save(feed)], "Expected to cache feed on load success")
    }

}

// MARK: - Helpers

private extension FeedLoaderCacheDecoratorTests {

    func makeSUT(
        loaderResult: FeedLoader.Result,
        cache: CacheSpy = CacheSpy(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedLoaderCacheDecorator {
        let loader = FeedLoaderStub(result: loaderResult)
        let sut = FeedLoaderCacheDecorator(decoratee: loader, cache: cache)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    class CacheSpy: FeedCache {
        enum Message: Equatable {
            case save([FeedImage])
        }
        private(set) var messages = [Message]()

        func save(_ feed: [FeedImage], completion: @escaping SaveCompletion) {
            messages.append(.save(feed))
            completion(.success(()))
        }
    }

}
