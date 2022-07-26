#if DEBUG
import EssentialFeed
import UIKit

final class DebuggingSceneDelegate: SceneDelegate {

    // MARK: - Nested Types

    private class AlwaysFailingHTTPClient: HTTPClient {
        private class Task: HTTPClientTask {
            func cancel() {}
        }
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            let error = NSError(domain: "offline", code: -1)
            completion(.failure(error))
            return Task()
        }
    }

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        #if DEBUG
        if CommandLine.arguments.contains("-reset") {
            try? FileManager.default.removeItem(at: localStoreURL)
        }
        #endif

        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    override func makeHTTPClient() -> HTTPClient {
        if UserDefaults.standard.string(forKey: "connectivity") == "offline" {
            return AlwaysFailingHTTPClient()
        }
        return super.makeHTTPClient()
    }

}
#endif
