//
//  RxMogo+PagableSpore.swift
//  Pods
//
//  Created by Harly on 2017/9/16.
//
//

import UIKit
import RxSwift
import RxCocoa

public protocol PageBase: NeedHandleRequestError, HaveRequestRx {
  // MARK: - Inputs
  /// 全部刷新，上拉或者刚进来什么的
  var firstPage: PublishSubject<Void> { get set }
  
  /// 下一页能量
  var nextPage: PublishSubject<Void> { get set }
  
  /// 最后一页超级能量
  var finalPageReached: PublishSubject<Void> { get set }
  
  func basePagedRequest<Element>(request : @escaping (Pageable) -> Observable<ImmerseResult<([Element], Pageable), ApiError>>)-> Observable<[Element]>
}

extension PageBase {
  
  public var firstPage: PublishSubject<Void> {
    get {
      if let value = objc_getAssociatedObject(self, &AssociatedKeys.firstPage) as?  PublishSubject<Void> {
        return value
      }
      firstPage = PublishSubject<Void>()
      return firstPage
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.firstPage, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public var nextPage: PublishSubject<Void> {
    get {
      if let value = objc_getAssociatedObject(self, &AssociatedKeys.nextPage) as?  PublishSubject<Void> {
        return value
      }
      nextPage = PublishSubject<Void>()
      return nextPage
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.nextPage, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public var finalPageReached: PublishSubject<Void> {
    get {
      if let value = objc_getAssociatedObject(self, &AssociatedKeys.finalPage) as?  PublishSubject<Void> {
        return value
      }
      finalPageReached = PublishSubject<Void>()
      return finalPageReached
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.finalPage, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public func basePagedRequest<Element>(request : @escaping (Pageable) -> Observable<ImmerseResult<([Element], Pageable), ApiError>>)-> Observable<[Element]> {
    return base(request: request)
  }
  
  func base<Element>(request : @escaping (Pageable) -> Observable<ImmerseResult<([Element], Pageable), ApiError>>)-> Observable<[Element]> {
    let loadNextPageTrigger: (Driver<PageableRepositoryState<Element>>) -> Driver<()> = { state in
      return self.nextPage.asDriver(onErrorJustReturn: ()).withLatestFrom(state).do(onNext: { state in
        
        if let page = state.pageInfo ,
          page.currentPage >= page.totalPage {
          self.finalPageReached.onNext(())
        }
        
      }).flatMap({ state -> Driver<()> in
        !state.shouldLoadNextPage
          ? Driver.just(())
          : Driver.empty()
      })
    }
    
    let performSearch: ((Pageable) -> Observable<PageResponse<Element>>) = {[weak self] page -> Observable<ImmerseResult<([Element], Pageable), ApiError>> in
      guard let strongSelf = self else { return Observable.empty() }
      return strongSelf.trackRequest(signal: request(page))
    }
    
    let repo = pagableRepository(allRefresher: firstPage.asDriver(onErrorJustReturn: ()),
                                 loadNextPageTrigger: loadNextPageTrigger,
                                 performSearch: performSearch) {[weak self] (error) in
                                  guard let strongSelf = self else { return }
                                  strongSelf.errorProvider
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

/// 分页实现 
public protocol PagableRequest: PageBase {
  
  // MARK: - Outputs
  /// 获取page
  ///
  /// - Parameter request: pureRequest之类的
  /// - Returns: Observable T
  func pagedRequest<Element>(request : @escaping (Pageable) -> Observable<ImmerseResult<([Element], Pageable), ApiError>>)-> Observable<[Element]>
}

// MARK: - Page
public extension PagableRequest {
  
  public func pagedRequest<Element>(request : @escaping (Pageable) -> Observable<ImmerseResult<([Element], Pageable), ApiError>>)-> Observable<[Element]> {
    return basePagedRequest(request: request)
  }
}

/// Page Extension
public protocol PageableJSONRequest: PageBase {
  associatedtype PageJSONType
  
  /// 整个请求对象类型
  var jsonOutputer: PublishSubject<PageJSONType> { get set }
}

extension PageableJSONRequest {
  
  /// page请求究极体
  ///
  /// - Parameters:
  ///   - request: 你的request
  ///   - resolver: resolver，告诉我你的list是哪个
  /// - Returns: 原来的Observer
  public func pagedRequest<Element>(
    request : @escaping (Pageable) -> Observable<ImmerseResult<([String: Any], Pageable), ApiError>>,
    resolver : @escaping (PageJSONType) -> [Element])
    -> Observable<[Element]> where PageJSONType: ModelType {
      func pageInfo(page: Pageable)
        -> Observable<ImmerseResult<([Element], Pageable), ApiError>> {
          let pageRequest = request(page).map({[weak self] result -> ImmerseResult<([Element], Pageable), ApiError> in
            guard let strongSelf = self else { return
              ImmerseResult(error: ApiError("000", message: "")) }
            switch result {
            case .success(let obj) :
              let pageObj = JSONDecoder.mainDecoder().decode(PageJSONType.self, fromAny: obj.0)!
              let pageArray = resolver(pageObj)
              strongSelf.jsonOutputer.onNext(pageObj)
              
              return ImmerseResult(value: (pageArray, obj.1))
            case .failure :
              return ImmerseResult(error: result.error ??
                ApiError("000", message: "不明错误出现咯"))
            }
          })
          
          return pageRequest
      }
      
      return basePagedRequest(request: { page -> Observable<ImmerseResult<([Element], Pageable), ApiError>> in
        return pageInfo(page: page)
      })
  }
  
}

/// Page Extension
public protocol PageExtensible: class {
  
  var pageOutputer: PublishSubject<Pageable> { get set }
}

extension PageBase where Self: PageExtensible {
  
  public func basePagedRequest<Element>(request : @escaping (Pageable) -> Observable<ImmerseResult<([Element], Pageable), ApiError>>)-> Observable<[Element]> {
    func pageInfo(page: Pageable)
      -> Observable<ImmerseResult<([Element], Pageable), ApiError>> {
        let pageRequest = request(page).map({[weak self] result -> ImmerseResult<([Element], Pageable), ApiError> in
          guard let strongSelf = self else { return
            ImmerseResult(error: ApiError("000", message: "")) }
          switch result {
          case .success(let obj) :
            strongSelf.pageOutputer.onNext(obj.1)
            return ImmerseResult(value: (obj.0, obj.1))
          case .failure :
            return ImmerseResult(error: result.error ??
              ApiError("000", message: "不明错误出现咯"))
          }
        })
        
        return pageRequest
    }
    
    return base(request: { page -> Observable<ImmerseResult<([Element], Pageable), ApiError>> in
      return pageInfo(page: page)
    })
  }
}
