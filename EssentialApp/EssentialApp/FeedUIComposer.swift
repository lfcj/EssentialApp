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

        let feedViewController = makeFeedViewController(
            onRefreshHandler: feedLoaderPresentationAdapter.loadResource,
            title: FeedPresenter.title)

        feedLoaderPresentationAdapter.presenter = LoadResourcePresenter(
            mapper: FeedPresenter.map,
            resourceView: FeedViewAdapter(controller: feedViewController, loader: imageLoader),
            loadingView: WeakRefVirtualProxy(feedViewController),
            errorView: WeakRefVirtualProxy(feedViewController)
        )
        return feedViewController
    }

    private static func makeFeedViewController(onRefreshHandler: @escaping ListViewController.RefreshHandler, title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedViewController = storyboard.instantiateInitialViewController() as! ListViewController
        feedViewController.title = title
        feedViewController.onRefresh = onRefreshHandler

        return feedViewController
    }

}
