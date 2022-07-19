import EssentialApp
import EssentialFeed
import XCTest

final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {

    private class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?

        func cancel() {
            wrapped?.cancel()
        }
    }

    private let decoratee: FeedImageDataLoader

    init(decoratee: FeedImageDataLoader) {
        self.decoratee = decoratee
    }

    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        decoratee.loadImageData(from: url, completion: completion)
    }

    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {}

}

final class FeedImageDataLoaderCacheDecoratorTests: XCTestCase, FeedImageDataLoaderTestCase {

    func test_load_deliversFeedImageOnLoaderSuccess() {
        let data = anyData()
        let (sut, loader) = makeSUT()

        expect(sut, toCompleteWith: .success(data)) {
            loader.complete(with: data)
        }
    }

}

// MARK: - Helpers

private extension FeedImageDataLoaderCacheDecoratorTests {

    func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (FeedImageDataLoaderCacheDecorator, FeedImageDataLoaderSpy) {
        let decoratee = FeedImageDataLoaderSpy()
        let decorator = FeedImageDataLoaderCacheDecorator(decoratee: decoratee)
        trackForMemoryLeaks(decorator, file: file, line: line)
        return (decorator, decoratee)
    }

}
