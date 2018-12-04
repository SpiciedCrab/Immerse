//
//  RxMogo+SporeNetworking.swift
//  RxMogo
//
//  Created by Harly on 2017/8/26.
//  Copyright © 2017年 Harly. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension Observable {
  private func track(activity : ActivityIndicator? = nil) -> Observable<Element> {
    guard let realTracker = activity else { return self }
    return self.trackActivity(realTracker)
  }
}

extension Observable where Element == ImmerseResult<[String: Any], ApiError>  {
  
  /// 返回一个单纯的请求JSON
  ///
  /// - Parameter tracking: activityIndicator是个转圈标示
  /// - Returns: Observable<JSON>
  func pure(tracking : ActivityIndicator? = nil) -> Observable<[String: Any]> {
    return track(activity: tracking)
      .filter({ result -> Bool in
        switch result {
        case .success :
          return true
        case .failure :
          return false
        }
      }).map { result -> [String: Any]? in
        switch result {
        case .success (let obj):
          return obj
          
        default:
          return nil
        }
        // swiftlint:disable:next force_unwrapping
      }.map { $0! }
  }
  
  /// 过滤下错误呗，错误会被输入到你的errorProvider里
  ///
  /// - Parameter errorProvider: 错误输出
  /// - Returns: 原版请求还给你啦
  func trackError(errorProvider: PublishSubject<RxError>) -> Observable<Element> {
    
    return self.do(onNext: { (result) in
      switch result {
        
      case .failure(let error):
        
        errorProvider.onNext(RxError.buildError(identifier: "\(self)",
                                                error: error))
        
      default:
        break
      }
    })
  }
  
  func mapToPageable(listKey: String) -> Observable<PageResponse<[String : Any]>> {
    let res = self.map { (result) -> ImmerseResult<([[String : Any]], Pageable), ApiError> in
      switch result {
      case .success (let obj):
        let page = Pageable(current: obj["currentPage"] as? Int ?? 0 , total: obj["total"] as? Int ?? 0)
        let list = obj[listKey] as? [[String: Any]] ?? []
        return ImmerseResult<([[String : Any]], Pageable), ApiError>(value: (list , page))
      case .failure(let error):
        return ImmerseResult(error: error)
      }
    }
    
    return res
  }
}

extension Observable where Element == PageResponse<[String : Any]> {

  func paging(pageContainer : PagableRequest ,
              pageChanged: @escaping (Pageable) -> ()) -> Observable<[[String : Any]]> {
    
    let loadNextPageTrigger: (Driver<PageableRepositoryState<[String : Any]>>) -> Driver<()> = { state in
      return pageContainer.nextPage.asDriver(onErrorJustReturn: ()).withLatestFrom(state).do(onNext: { state in
        
        if let page = state.pageInfo ,
          page.currentPage >= page.totalPage {
          pageContainer.finalPageReached.onNext(())
        }
        
      }).flatMap({ state -> Driver<()> in
        !state.shouldLoadNextPage
          ? Driver.just(())
          : Driver.empty()
      })
    }
    
    let performRequest: ((Pageable) -> Observable<PageResponse<[String : Any]>>) = {[weak self] page -> Observable<PageResponse<[String : Any]>> in
      guard let `self` = self else { return Observable.empty() }
      pageChanged(page)
      return self.track(activity: pageContainer.loadingActivity)
    }
    
    
    let repo = pagableRepository(allRefresher: pageContainer.firstPage.asDriver(onErrorJustReturn: ()),
                                 loadNextPageTrigger: loadNextPageTrigger,
                                 performSearch: performRequest) {(error) in
                                  pageContainer.errorProvider
                                    .onNext(RxError.buildError(identifier: "pageError",
                                                               error: error))
    }
    return repo.asObservable()
      .do(onNext: { element in
        print(element)
      })
      .map { $0.repositories }
      .map { $0.value }
  }
}

