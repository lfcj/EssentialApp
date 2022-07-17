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
        let loader = LoaderStub(result: .success(feed))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)

        expect(sut, toCompleteWith: .success(feed))
    }

    func test_load_deliversErrorOnLoaderFailure() {
        let error = anyError()t
        let loader = LoaderStub(result: .failure(error))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)

        expect(sut, toCompleteWith: .failure(error))
    }

}

// MARK: - Helpers

private extension FeedLoaderCacheDecoratorTests {

    func expect(
        _ sut: FeedLoaderCacheDecorator,
        toCompleteWith expectedResult: FeedLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Expect remote feed")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedFeed), .success(let expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
            case (.failure(let receivedError), .failure(let expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) and received \(receivedResult)", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    class LoaderStub: FeedLoader {
        private let result: FeedLoader.Result
        init(result: FeedLoader.Result) {
            self.result = result
        }
        func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
            completion(result)
        }
    }
    
}
