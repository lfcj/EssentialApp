import Combine
import Foundation
import EssentialFeed
import EssentialFeediOS
import UIKit

public final class CommentsUIComposer {
    private init() {}
    public static func commentsComposed(
        withCommentsLoader commentsLoader: @escaping () -> LocalFeedLoader.Publisher
    ) -> ListViewController {
        let feedLoaderPresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(loader: commentsLoader)

        let feedViewController = makeFeedViewController(
            onRefreshHandler: feedLoaderPresentationAdapter.loadResource,
            title: FeedPresenter.title)

        feedLoaderPresentationAdapter.presenter = LoadResourcePresenter(
            mapper: FeedPresenter.map,
            resourceView: FeedViewAdapter(
                controller: feedViewController,
                loader: { _ in Empty<Data, Error>().eraseToAnyPublisher() }
            ),
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
