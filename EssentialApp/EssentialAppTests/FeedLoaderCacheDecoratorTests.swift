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

}

// MARK: - Helpers

private extension FeedLoaderCacheDecoratorTests {

    func makeSUT(
        loaderResult: FeedLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedLoaderCacheDecorator {
        let loader = FeedLoaderStub(result: loaderResult)
        let sut = FeedLoaderCacheDecorator(decoratee: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

}
