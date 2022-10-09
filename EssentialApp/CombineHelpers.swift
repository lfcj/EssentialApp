import Combine
import EssentialFeed
import Foundation

public extension FeedLoader {

    typealias Publisher = AnyPublisher<[FeedImage],  Error>

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

extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: cache.saveIgnoringResult)
             .eraseToAnyPublisher()
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
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ data: Data, for url: URL) {
        self.save(data, for: url) { _ in }
    }
}
