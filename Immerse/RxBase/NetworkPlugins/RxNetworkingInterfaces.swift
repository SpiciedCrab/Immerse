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

struct AssociatedKeys {
  static var loading = "LoadingProvider"
  static var error = "ErrorProvider"
  static var firstPage = "firstPage"
  static var nextPage = "lastPage"
  static var finalPage = "finalPage"
}


//这是个有请求就必须带着的协议哟
// MARK: - RxRenterRequest协议
public protocol HaveRequestRx: class {
  /// 获取一个纯洁的请求，请求Error是不会走下去的，只会走成功的情况
  ///
  /// - Parameter requestSignal: Wings层来的请求
  /// - Returns: 你想要的请求砖头
  func pureRequest<Element>(withResultSignal requestSignal: Observable<ImmerseResult<Element, ApiError>>) -> Observable<Element>
  
  /// 获取一个纯洁的请求，请求Error是不会走下去的，只会走成功的情况
  ///
  /// - Parameter requestAction: 请求block
  /// - Returns: 你想要的请求砖头
  func pureRequest<Element>(withResultAction requestAction: (() -> Observable<ImmerseResult<Element, ApiError>>)) -> Observable<Element>
  
  var loadingActivity: ActivityIndicator { get set }
  
  func trackLoadMySelf() -> Bool
}

// HaveRequestRx 实现咯
public extension HaveRequestRx {
  
  public var loadingActivity: ActivityIndicator {
    get {
      if let value = objc_getAssociatedObject(self, &AssociatedKeys.loading) as?  ActivityIndicator {
        return value
      }
      loadingActivity = ActivityIndicator()
      return loadingActivity
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.loading, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  func trackLoadMySelf() -> Bool {
    return false
  }
  
  func pureRequest<Element>(withResultAction
    requestAction: (() -> Observable<ImmerseResult<Element, ApiError>>)) -> Observable<Element> {
    return pureRequest(withResultSignal: requestAction())
  }
  
  func pureRequest<Element>(withResultSignal requestSignal: Observable<ImmerseResult<Element, ApiError>>) -> Observable<Element> {
    return trackRequest(signal: requestSignal)
      .filter({ result -> Bool in
        switch result {
        case .success :
          return true
        case .failure :
          return false
        }
      }).map { result -> Element? in
        switch result {
        case .success (let obj):
          return obj
          
        default:
          return nil
        }
        // swiftlint:disable:next force_unwrapping
      }.map { $0! }
  }
  
  /// 跟踪某个请求
  ///
  /// - Parameter signal: 信号
  /// - Returns: 原封不动还给你
  func trackRequest<Element>(signal: Observable<Element>) -> Observable<Element> {
    return self.trackLoadMySelf() ? signal : signal.trackActivity(self.loadingActivity)
  }
}

//如果你想处理错误，那就一起接上他咯
// MARK: - RxMogo Error Handle协议
public protocol NeedHandleRequestError : class {
  /// 错误能量之源呐
  var errorProvider: PublishSubject<RxError> { get set }
  
  /// 返回纯洁的能量，当错误时候把能量会给到errorProvider
  ///
  /// - Parameters:
  ///   - requestSignal: Wings层来的请求
  ///   - key: 错误标识
  /// - Returns: 你想要的请求
  func requestAfterErrorFilterd<Element>(withResultSignal requestSignal: Observable<ImmerseResult<Element, ApiError>>, withFlag key: String?) -> Observable<Element>
  
  /// 返回纯洁的能量，当错误时候把能量会给到errorProvider
  ///
  /// - Parameters:
  ///   - requestAction: Wings层来的请求做的block哟
  ///   - key: 错误标识
  /// - Returns: 你想要的请求
  func requestAfterErrorFilterd<Element>(withResultAction requestAction: (() -> Observable<ImmerseResult<Element, ApiError>>),
                                         withFlag key: String?) -> Observable<Element>
  
  /// 返回纯洁的能量，当错误时候把能量会给到errorProvider
  ///
  /// - Parameters:
  ///   - requestAction: Wings层来的请求做的block哟
  ///   - key: 错误标识
  /// - Returns: 你想要的请求
  func requestAfterErrorFilterd<Element>(withResultAction requestAction: (() -> Observable<ImmerseResult<Element, ApiError>>), withFlag key: String?) -> Observable<RxBricks<Element>>
  
}

// 处理错误的方法
public extension NeedHandleRequestError where Self: HaveRequestRx {
  
  public var errorProvider: PublishSubject<RxError> {
    get {
      if let value = objc_getAssociatedObject(self, &AssociatedKeys.error) as?  PublishSubject<RxError> {
        return value
      }
      errorProvider = PublishSubject<RxError>()
      return errorProvider
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.error, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  func requestAfterErrorFilterd<Element>(withResultAction requestAction: (() -> Observable<ImmerseResult<Element, ApiError>>),
                                         withFlag key: String?) -> Observable<RxBricks<Element>> {
    return requestAfterErrorFilterd(withResultSignal: requestAction(), withFlag: key).map { RxBricks.finished(result: $0) }
  }
  
  func requestAfterErrorFilterd<Element>(withResultAction requestAction: (() -> Observable<ImmerseResult<Element, ApiError>>),
                                         withFlag key: String?) -> Observable<Element> {
    return requestAfterErrorFilterd(withResultSignal: requestAction(), withFlag: key)
  }
  
  func requestAfterErrorFilterd<Element>(
    withResultSignal requestSignal: Observable<ImmerseResult<Element, ApiError>> ,
    withFlag key: String? = nil) -> Observable<Element> {
    let filteredResult = trackRequest(signal: requestSignal).do(onNext: {[weak self]result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .failure(let error):
        
        let t = DispatchTime.now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: t, execute: {
          strongSelf.errorProvider.onNext(RxError.buildError(identifier: key,
                                                             error: error))
        })
        
      default:
        break
      }
    })
    
    return pureRequest(withResultSignal: filteredResult)
  }
}
