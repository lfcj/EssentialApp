import EssentialFeed
import XCTest

protocol FeedLoaderTestCase: XCTestCase {}

extension FeedLoaderTestCase {

    func expect(
        _ sut: FeedLoader,
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

}
