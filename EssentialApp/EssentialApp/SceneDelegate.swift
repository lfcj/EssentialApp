import Combine
import CoreData
import EssentialFeed
import EssentialFeediOS
import os
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var scheduler: AnyDispatchQueueScheduler = DispatchQueue(
        label: "lfcj.EssentialApp.infra.queue",
        qos: .userInitiated,
        attributes: .concurrent
    ).eraseToAnyScheduler()

    private lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    private lazy var logger = Logger(subsystem: "lfcj.EssentialApp", category: "main")
    private lazy var localStore: FeedStore & FeedImageDataStore = {
        do {
            return try CoreDataFeedStore(
                storeURL: NSPersistentContainer
                    .defaultDirectoryURL()
                    .appendingPathComponent("feed-store.sqlite")
            )
        } catch {
            assertionFailure("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
            logger.fault("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
            return NullStore()
        }
    }()

    private lazy var localFeedLoader = LocalFeedLoader(store: localStore, currentDate: Date.init)

    private lazy var baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!

    private lazy var navigationController: UINavigationController = UINavigationController(
        rootViewController: FeedUIComposer.feedComposed(
            withFeedLoader: makeRemoteFeedLoaderWithLocalFallback,
            imageLoader: makeLocalImageLoaderWithRemoteFallback,
            selectionHandler: showComments
        )
    )

    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore, scheduler: AnyDispatchQueueScheduler) {
        self.init()
        self.httpClient = httpClient
        self.localStore = store
        self.scheduler = scheduler
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        configureWindow()
    }

    func configureWindow() {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        do {
            try localFeedLoader.validateCache()
        } catch {
            logger.error("Failed to validate cache with error: \(error.localizedDescription)")
        }
    }

    private func showComments(for image : FeedImage) {
        let commentsViewController = CommentsUIComposer.commentsComposed(
            withCommentsLoader: makeRemoteCommentsLoader(url: ImageCommentsEndpoint.get(image.id).url(baseURL: baseURL))
        )

        navigationController.pushViewController(commentsViewController, animated: true)
    }

    private func makeRemoteCommentsLoader(url: URL) -> () -> CommentsUIComposer.ImageCommentsPublisher {
        { [httpClient] in
            httpClient
                .getPublisher(url: url)
                .tryMap(ImageCommentsMapper.map)
                .eraseToAnyPublisher()
        }
    }
 
    private func makeRemoteFeedLoaderWithLocalFallback() -> LocalFeedLoader.PaginatedPublisher  {
        makeRemoteFeedLoader()
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
            .map(makeFirstPage)
            .subscribe(on: scheduler)
            .eraseToAnyPublisher()
    }

    private func makeRemoteLoadMoreLoader(items: [FeedImage], last: FeedImage?) -> (() -> AnyPublisher<Paginated<FeedImage>, Error>)? {
        last.map { lastItem in
            let url = FeedEndpoint.get(after: lastItem).url(baseURL: baseURL)

            return { [httpClient, localFeedLoader] in
                httpClient
                    .getPublisher(url: url)
                    .tryMap(FeedItemsMapper.map)
                    .map { newItems in
                        let allItems = items + newItems
                        return Paginated(
                            items: allItems,
                            loadMorePublisher: self.makeRemoteLoadMoreLoader(items: allItems, last: newItems.last)
                        )
                    }
                    .caching(to: localFeedLoader)
            }
        }
    }

    private func makeLocalImageLoaderWithRemoteFallback(url: URL) -> FeedImageDataLoader.Publisher {
        let localImageLoader = LocalFeedImageDataLoader(store: localStore)

        return localImageLoader
            .loadImageDataPublisher(from: url)
            .fallback(to: { [httpClient, scheduler] in
                httpClient
                    .getPublisher(url: url)
                    .tryMap(FeedImageDataMapper.map)
                    .caching(to: localImageLoader, using: url)
                    .subscribe(on: scheduler)
                    .eraseToAnyPublisher()
            })
            .subscribe(on: scheduler)
            .eraseToAnyPublisher()
    }

    private func makeRemoteFeedLoader(after: FeedImage? = nil) -> AnyPublisher<[FeedImage], Error> {
        let url = FeedEndpoint.get(after: after).url(baseURL: baseURL)
        return httpClient
            .getPublisher(url: url)
            .tryMap(FeedItemsMapper.map)
            .eraseToAnyPublisher()
    }

    private func makeFirstPage(items: [FeedImage]) -> Paginated<FeedImage> {
        makePage(items: items, last: items.last)
    }

    private func makePage(items: [FeedImage], last: FeedImage?) -> Paginated<FeedImage> {
        Paginated(items: items, loadMorePublisher: last.map { last in
            { self.makeRemoteLoadMoreLoader(last: last) }
        })
    }

    private func makeRemoteLoadMoreLoader(last: FeedImage?) -> AnyPublisher<Paginated<FeedImage>, Error> {
        localFeedLoader.loadPublisher()
            .zip(makeRemoteFeedLoader(after: last))
            .map { cachedItems, newItems in
                (cachedItems + newItems, newItems.last)
            }
            .map(makePage)
            .caching(to: localFeedLoader)
            .subscribe(on: scheduler)
            .eraseToAnyPublisher()
    }

}
