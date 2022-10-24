import Combine
import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

class CommonUIIntegrationTests: FeedUIIntegrationTests {
    
    func test_commentsView_hasTitle() {
        let (sut, _) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.title, commentsTitle)
    }

    func test_loadCommentsActions_requestCommentsFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCommentsCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCommentsCallCount, 1, "Expected a loading request once view is loaded")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCommentsCallCount, 2, "Expected another loading requests once user initiates a load")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCommentsCallCount, 3, "Expected a third loading requests once user initiates another load")
    }

    func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loader.completeCommentsLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed successfully")

        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

        loader.completeCommentsLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading is completed with error")
    }

    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let comment0 = makeComment(message: "a message", username: "a username")
        let comment1 = makeComment(message: "another message", username: "another username")
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
 
        loader.completeCommentsLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])

        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }

    func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() {
        let comment = makeComment()
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])

        loader.completeCommentsLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])

        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
    }

    func test_loadCommentsCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeCommentsLoading(at: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let comment = makeComment()
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeCommentsLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])

        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment])
    }

    override func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeCommentsLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.errorView.simulateTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }

    override func test_tappingOnErrorView_hidesIt() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeCommentsLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (ListViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsComposed(withCommentsLoader: loader.loadPublisher)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }

    private func makeComment(message: String = "any", username: String = "any") -> ImageComment {
        ImageComment(id: UUID(), message: message, createdDate: Date(), username: username)
    }

    func assertThat(
        _ sut: ListViewController,
        isRendering comments: [ImageComment],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        sut.tableView.layoutIfNeeded()
        RunLoop.main.run(until: Date())

        XCTAssertEqual(sut.numberOfRenderedComments(), comments.count, "comments count", file: file, line: line)
        comments.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index, file: file, line: line)
        }
    }

    private func assertThat(
        _ sut: ListViewController,
        hasViewConfiguredFor comment: ImageComment,
        at index: Int = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let view = sut.imageCommentView(at: index) as? ImageCommentCell
        let viewModel = ImageCommentsPresenter.map([comment]).comments[0]
        XCTAssertNotNil(view)
        XCTAssertEqual(view?.messageLabel.text, viewModel.message, file: file, line: line)
        XCTAssertEqual(view?.usernameLabel.text, viewModel.username, file: file, line: line)
        XCTAssertEqual(view?.dateLabel.text, viewModel.createAtMessage, file: file, line: line)
    }

    // MARK: - Nested Types

    private class LoaderSpy {

        private var requests = [PassthroughSubject<[ImageComment], Error>]()

        var loadCommentsCallCount: Int { requests.count }
        private(set) var cancelledImageURLs = [URL]()

        func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeCommentsLoading(with comments: [ImageComment] = [], at index: Int = 0) {
            requests[index].send(comments)
        }

        func completeCommentsLoadingWithError(at index: Int = 0) {
            requests[index].send(completion: .failure(anyNSError()))
        }

        private func anyNSError() -> NSError {
            NSError(domain: "any", code: 0, userInfo: nil)
        }

    }
}

