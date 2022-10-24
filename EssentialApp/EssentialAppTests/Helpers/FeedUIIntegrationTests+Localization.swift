import EssentialFeed
import EssentialFeediOS
import Foundation
import XCTest

extension FeedUIIntegrationTests {
    var loadError: String { LoadResourcePresenter<Any, DummyView>.loadError }
    var feedTitle: String { FeedPresenter.title }
    var commentsTitle: String { ImageCommentsPresenter.title }

    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }
}
