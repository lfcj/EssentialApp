import EssentialFeed
import XCTest

final class FeedLoaderWithFallbackComposite: FeedLoader {

    private let primaryLoader: FeedLoader
    private let fallbackLoader: FeedLoader

    init(primaryLoader: FeedLoader, fallbackLoader: FeedLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    func load(completion: @escaping (FeedLoader.Result) -> Void) {
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

class FeedLoaderWithFallbackCompositeTests: XCTestCase {

    func test_load_deliversPrimaryFeedOnPrimarySuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let expectedResult = FeedLoader.Result.success(primaryFeed)
        let sut = makeSUT(primaryResult: expectedResult, fallbackResult: .success(fallbackFeed))

        expect(sut, toCompleteWith: expectedResult)
    }

    func test_load_deliversFallbackFeedOnPrimaryFailure() {
        let primaryError = NSError()
        let fallbackFeed = uniqueFeed()
        let expectedResult = FeedLoader.Result.success(fallbackFeed)
        let sut = makeSUT(primaryResult: .failure(primaryError), fallbackResult: expectedResult)

        expect(sut, toCompleteWith: expectedResult)
    }

    func test_load_deliversFallbackErrorWhenBothPrimaryAndFallbackLoadsFails() {
        let primaryError = NSError(domain: "primary error", code: 0)
        let fallbackError = NSError(domain: "fallback error", code: 0)
        let expectedResult = FeedLoader.Result.failure(fallbackError)
        let sut = makeSUT(primaryResult: .failure(primaryError), fallbackResult: expectedResult)

        expect(sut, toCompleteWith: expectedResult)
    }

}

private extension FeedLoaderWithFallbackCompositeTests {

    func makeSUT(
        primaryResult: FeedLoader.Result,
        fallbackResult: FeedLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedLoaderWithFallbackComposite {
        let primaryLoader = LoaderStub(result: primaryResult)
        let fallbackLoader = LoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return sut
    }

    func expect(
        _ sut: FeedLoaderWithFallbackComposite,
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

    func uniqueFeed() -> [FeedImage] {
        [FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())]
    }

    func anyURL() -> URL {
        URL(string: "https://www.any-url.com")!
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }

    final class LoaderStub: FeedLoader {
        private let result: FeedLoader.Result

        init(result: FeedLoader.Result) {
            self.result = result
        }
        func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
            completion(result)
        }
    }
}
