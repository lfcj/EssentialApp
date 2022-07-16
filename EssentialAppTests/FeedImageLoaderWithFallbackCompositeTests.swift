import EssentialFeed
import XCTest

class FeedImageLoaderWithFallbackComposite: FeedImageDataLoader {

    private let primaryLoader: FeedImageDataLoader
    private let fallbackLoader: FeedImageDataLoader

    init(primaryLoader: FeedImageDataLoader, fallbackLoader: FeedImageDataLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        primaryLoader.loadImageData(from: url, completion: completion)
    }
    
    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        primaryLoader.save(data, for: url, completion: completion)
    }
    
}

final class FeedImageLoaderWithFallbackCompositeTests: XCTestCase {

    func test_load_deliversPrimaryImageDataOnPrimarySuccess() {
        let primaryImageData = anyData()
        let fallbackImageData = anyData()
        let expectedResult = FeedImageDataLoader.Result.success(primaryImageData)
        let sut = makeSUT(primaryResult: expectedResult, fallbackResult: .success(fallbackImageData))

        expect(sut, toCompleteWith: expectedResult)
    }

}

private extension FeedImageLoaderWithFallbackCompositeTests {

    func makeSUT(
        primaryResult: FeedImageDataLoader.Result,
        fallbackResult: FeedImageDataLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedImageLoaderWithFallbackComposite {
        let primaryLoader = LoaderStub(result: primaryResult)
        let fallbackLoader = LoaderStub(result: fallbackResult)
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return sut
    }

    func expect(
        _ sut: FeedImageLoaderWithFallbackComposite,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Expect remote feed")
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
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

    final class TaskStub: FeedImageDataLoaderTask {
        
        func cancel() {}
    }
    final class LoaderStub: FeedImageDataLoader {
        private let result: FeedImageDataLoader.Result

        init(result: FeedImageDataLoader.Result) {
            self.result = result
        }

        func loadImageData(
            from url: URL,
            completion: @escaping (FeedImageDataLoader.Result) -> Void
        ) -> FeedImageDataLoaderTask {
            completion(result)
            return TaskStub()
        }

        func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {

        }
    }

}
