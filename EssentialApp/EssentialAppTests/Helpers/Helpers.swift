import EssentialFeed
import Foundation

func uniqueFeed() -> [FeedImage] {
    [FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())]
}

func anyError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    URL(string: "https://www.any-url.com")!
}

func anyData() -> Data {
    Data("any data".utf8)
}


