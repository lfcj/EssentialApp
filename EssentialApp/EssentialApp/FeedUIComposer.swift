import Foundation
import EssentialFeed
import EssentialFeediOS
import UIKit

public final class FeedUIComposer {
    private init() {}
    public static func feedComposed(
        withFeedLoader feedLoader: @escaping () -> LocalFeedLoader.Publisher,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
    ) -> ListViewController {
        let feedLoaderPresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(loader: feedLoader)

        let feedViewController = makeFeedViewController(delegate: feedLoaderPresentationAdapter, title: FeedPresenter.title)

        feedLoaderPresentationAdapter.presenter = LoadResourcePresenter(
            mapper: FeedPresenter.map,
            resourceView: FeedViewAdapter(controller: feedViewController, loader: imageLoader),
            loadingView: WeakRefVirtualProxy(feedViewController),
            errorView: WeakRefVirtualProxy(feedViewController)
        )
        return feedViewController
    }

    private static func makeFeedViewController(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedViewController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedViewController.title = title
        feedViewController.delegate = delegate

        return feedViewController
    }

}
