//
//  RxMogo+PageCook.swift
//  Pods
//
//  Created by Harly on 2017/9/16.
//
//

import UIKit
import RxSwift
import RxCocoa
public typealias PageResponse<Element> = ImmerseResult<([Element], Pageable), ApiError>

internal enum PagableRequestCommand<Element> {
    case refreshAll
    case loadMoreItems
    case responseRecieved(PageResponse<Element>)
}

public struct PageableRepositoryState<RepositoryElement> : Mutable, Statable {

    var shouldLoadNextPage: Bool

    public var isLoading: Bool

    public var repositories: Version<[RepositoryElement]>

    var failure: ApiError?

    var pageInfo: Pageable?

    public var isFailed: Bool {
        return failure != nil
    }

    init() {

        isLoading = false
        shouldLoadNextPage = true
        repositories = Version([])
        failure = nil
    }
}

extension PageableRepositoryState {

    static func buildNewState() -> PageableRepositoryState<RepositoryElement> {
        return PageableRepositoryState()
    }

    static func reduce(state: PageableRepositoryState, command: PagableRequestCommand<RepositoryElement>) -> PageableRepositoryState {
        switch command {
        case .refreshAll:
            return PageableRepositoryState().mutateOne {
                $0.failure = state.failure
                $0.pageInfo = Pageable()
                $0.isLoading = false
            }
        case .responseRecieved(let result):

            switch result {
            case .success(let realResult):
                    return state.mutate {
                        $0.repositories = Version($0.repositories.value + realResult.0)
                        $0.shouldLoadNextPage = false
                        $0.failure = nil
                        $0.pageInfo = realResult.1
                        $0.isLoading = true
                    }
            case .failure(let error):
                return state.mutate {
                    $0.repositories = Version([])
                    $0.shouldLoadNextPage = false
                    $0.failure = error
                    $0.pageInfo = Pageable()
                    $0.isLoading = true
                }
            }

        case .loadMoreItems:
            return state.mutate {
                if $0.failure == nil, let realPage = $0.pageInfo {
                    $0.shouldLoadNextPage = realPage.currentPage < realPage.totalPage
                }

                $0.isLoading = false
            }
        }
    }
}

public func pagableRepository<Element> (
    allRefresher: Driver<Void>,
    loadNextPageTrigger: @escaping (Driver<PageableRepositoryState<Element>>) -> Driver<()>,
    performSearch: @escaping (Pageable) -> Observable<PageResponse<Element>> ,
    errorTrigger: ((ApiError) -> Void)? = nil
    ) -> Driver<PageableRepositoryState<Element>> {

    let searchPerformerFeedback: (Driver<PageableRepositoryState<Element>>) -> Driver<PagableRequestCommand<Element>> = { state in

        return state.map { (shouldLoadNextPage: $0.shouldLoadNextPage, page: $0.pageInfo) }

            // perform feedback loop effects
            .flatMapLatest { shouldLoadNextPage, page -> Driver<PagableRequestCommand<Element>> in
                if !shouldLoadNextPage {
                    return Driver.empty()
                }

                var finalPage = Pageable()

                if let realPage = page {
                    finalPage.currentPage = realPage.currentPage
                    finalPage.totalPage = realPage.totalPage
                }

                return performSearch(finalPage)
                    .asDriver(onErrorJustReturn: ImmerseResult(error: ApiError("-998", message: "欧，架构炸了快跑啊")))
                    .map(PagableRequestCommand.responseRecieved)
        }
    }

    let inputFeedbackLoop: (Driver<PageableRepositoryState<Element>>) -> Driver<PagableRequestCommand<Element>> = { state in
        let loadNextPage = loadNextPageTrigger(state).map { _ in PagableRequestCommand<Element>.loadMoreItems }
        let refresher = allRefresher.map { PagableRequestCommand<Element>.refreshAll }

        return Driver.merge(loadNextPage, refresher)
    }

    // Create a system with two feedback loops that drive the system
    // * one that tries to load new pages when necessary
    // * one that sends commands from user input
    return Driver.system(PageableRepositoryState.buildNewState(),
                         accumulator: PageableRepositoryState.reduce,
                         feedback: searchPerformerFeedback,
                         inputFeedbackLoop)
        .do(onNext: { state in
            guard let realError = state.failure else { return }
            guard let errorSender = errorTrigger else { return }
            errorSender(realError)
        })
        .filter { $0.isLoading || $0.isFailed }
}

internal func == (
    lhs: (shouldLoadNextPage: Bool, page: Pageable?),
    rhs: (shouldLoadNextPage: Bool, page: Pageable?)
    ) -> Bool {
    return lhs.shouldLoadNextPage == rhs.shouldLoadNextPage
        && lhs.page?.currentPage == rhs.page?.currentPage
}

//extension DemoRepositoryState {
//    var isOffline: Bool {
//        guard let failure = self.failure else {
//            return false
//        }
//
//        if case .offline = failure {
//            return true
//        }
//        else {
//            return false
//        }
//    }
//
//    var isLimitExceeded: Bool {
//        guard let failure = self.failure else {
//            return false
//        }
//
//        if case .githubLimitReached = failure {
//            return true
//        }
//        else {
//            return false
//        }
//    }
//}
