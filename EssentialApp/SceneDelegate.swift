import EssentialFeed
import EssentialFeediOS
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        let session = URLSession(configuration: .ephemeral)
        let client = URLSessionHTTPClient(session: session)

        let url = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let feedImageLoader = RemoteFeedImageDataLoader(client: client)
        let feedLoader = RemoteFeedLoader(url: url, client: client)
        let feedViewController = FeedUIComposer.feedComposed(with: feedLoader, imageLoader: feedImageLoader)

        window?.rootViewController = feedViewController
    }

}

