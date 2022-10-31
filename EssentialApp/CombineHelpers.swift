import Combine
import EssentialFeed
import Foundation

public extension HTTPClient {

    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse),  Error>

    func getPublisher(url: URL) -> Publisher {
        var task: HTTPClientTask?

        return Deferred {
            Future { completion in
                task = self.get(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }

}

public extension Paginated {

    init(items: [Item], loadMorePublisher: (() -> AnyPublisher<Self, Error>)?) {
        self.init(
            items: items,
            loadMoreHandler: loadMorePublisher.map { publisher in
                return { completion in
                    publisher().subscribe(
                        Subscribers.Sink(
                            receiveCompletion: { result in
                                if case let .failure(error) = result {
                                    completion(.failure(error))
                                }
                            },
                            receiveValue: { result in
                                completion(.success(result))
                            }
                        )
                    )
                 }
             }
        )
    }

    var loadMorePublisher: (() -> AnyPublisher<Self, Error>)? {
         guard let loadMoreHandler = loadMoreHandler else {
             return nil
         }

        return {
            Deferred {
                Future(loadMoreHandler)
                
            }.eraseToAnyPublisher()
        }
    }

 }

public extension LocalFeedLoader {

    typealias Publisher = AnyPublisher<[FeedImage],  Error>
    typealias PaginatedPublisher = AnyPublisher<Paginated<FeedImage>,  Error>

    func loadPublisher() -> Publisher {
        Deferred {
            Future(self.load)
        }
        .eraseToAnyPublisher()
    }

}

public extension FeedImageDataLoader {

    typealias Publisher = AnyPublisher<Data,  Error>

    func loadImageDataPublisher(from url: URL) -> Publisher {
        var task: FeedImageDataLoaderTask?

        return Deferred {
            Future { completion in
                task = self.loadImageData(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }

}

extension Publisher {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == [FeedImage] {
        handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }

    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == Paginated<FeedImage> {
        handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
}

extension Publisher where Output == Data {
    func caching(to cache: FeedImageDataCache, using url: URL) -> AnyPublisher<Output, Failure> {
        handleEvents(
            receiveOutput: { data in
                cache.saveIgnoringResult(data, for: url)
            }
        )
        .eraseToAnyPublisher()
    }
}


extension Publisher {
    func fallback(
        to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>
    ) -> AnyPublisher<Output, Failure> {
        self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

extension Publisher {
    func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.inmmediateWhenOnMainQueueScheduler).eraseToAnyPublisher()
    }
}

extension DispatchQueue {

    static var inmmediateWhenOnMainQueueScheduler: InmediateWhenOnMainQueueScheduler { InmediateWhenOnMainQueueScheduler() }

    struct InmediateWhenOnMainQueueScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions
        
        var now: DispatchQueue.SchedulerTimeType { DispatchQueue.main.now }
        var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }
        
        func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            guard Thread.isMainThread else {
                return DispatchQueue.main.schedule(options: options, action)
            }
            action()
        }

        func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }

        func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
            DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        }
    }

}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        self.save(feed) { _ in }
    }
    func saveIgnoringResult(_ page: Paginated<FeedImage>) {
        saveIgnoringResult(page.items)
    }
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ data: Data, for url: URL) {
        self.save(data, for: url) { _ in }
    }
}
