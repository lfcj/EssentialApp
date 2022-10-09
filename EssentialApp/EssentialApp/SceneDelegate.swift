import Combine
import CoreData
import EssentialFeed
import EssentialFeediOS
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    private lazy var localStore: FeedStore & FeedImageDataStore = try! CoreDataFeedStore(
        storeURL: NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("feed-store.sqlite")
    )
    private lazy var localFeedLoader = LocalFeedLoader(store: localStore, currentDate: Date.init)

    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore) {
        self.init()
        self.httpClient = httpClient
        self.localStore = store
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        configureWindow()
    }

    func configureWindow() {
        let remoteImageLoader = RemoteFeedImageDataLoader(client: httpClient)
        let localImageLoader = LocalFeedImageDataLoader(store: localStore)

        window?.rootViewController = UINavigationController(
            rootViewController: FeedUIComposer.feedComposed(
                withFeedLoader: makeFeedLoaderWithLocalFallback,
                imageLoader: FeedImageLoaderWithFallbackComposite(
                    primaryLoader: FeedImageDataLoaderCacheDecorator(
                        decoratee: remoteImageLoader,
                        cache: localImageLoader
                    ),
                    fallbackLoader: localImageLoader
                )
            )
        )
    }

    func sceneWillResignActive(_ scene: UIScene) {
        localFeedLoader.validateCache { _ in }
    }

    private func makeFeedLoaderWithLocalFallback() -> RemoteFeedLoader.Publisher  {
        let url = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let remoteFeedLoader = RemoteFeedLoader(url: url, client: httpClient)
        return remoteFeedLoader
            .loadPublisher()
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
    }
}

public extension FeedLoader {

    typealias Publisher = AnyPublisher<[FeedImage],  Error>

    func loadPublisher() -> Publisher {
        Deferred {
            Future(self .load)
        }
        .eraseToAnyPublisher()
    }

}

extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: cache.saveIgnoringResult)
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
