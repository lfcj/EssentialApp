import EssentialApp
import EssentialFeed
import XCTest

class FeedLoaderWithFallbackCompositeTests: XCTestCase, FeedLoaderTestCase {

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
        let primaryLoader = FeedLoaderStub(result: primaryResult)
        let fallbackLoader = FeedLoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return sut
    }

}
