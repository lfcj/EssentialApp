import Combine
import Foundation
import EssentialFeed
import EssentialFeediOS
import UIKit

public final class CommentsUIComposer {
    private typealias CommentsPresentationAdapter = LoadResourcePresentationAdapter<[ImageComment], CommentsViewAdapter>
    private init() {}
    public static func commentsComposed(
        withCommentsLoader commentsLoader: @escaping () -> AnyPublisher<[ImageComment],  Error>
    ) -> ListViewController {
        let commentLoaderPresentationAdapter = CommentsPresentationAdapter(loader: commentsLoader)

        let commentsViewController = makeCommentsViewController(
            onRefreshHandler: commentLoaderPresentationAdapter.loadResource,
            title: ImageCommentsPresenter.title)

        commentLoaderPresentationAdapter.presenter = LoadResourcePresenter(
            mapper: { ImageCommentsPresenter.map($0) },
            resourceView: CommentsViewAdapter(controller: commentsViewController),
            loadingView: WeakRefVirtualProxy(commentsViewController),
            errorView: WeakRefVirtualProxy(commentsViewController)
        )
        return commentsViewController
    }

    private static func makeCommentsViewController(onRefreshHandler: @escaping ListViewController.RefreshHandler, title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let commentsViewController = storyboard.instantiateInitialViewController() as! ListViewController
        commentsViewController.title = title
        commentsViewController.onRefresh = onRefreshHandler

        return commentsViewController
    }

}
