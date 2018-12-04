//
//  RxRequests.swift
//  LingoStudy
//
//  Created by CatHarly on 2018/9/10.
//  Copyright © 2018年 LLS iOS Team. All rights reserved.
//

import Foundation
import RxSwift
import LLSFoundation

protocol RxRequestable {
  
}

extension RxRequestable {
  func obsRequest(payload: HTTPConvertible) -> Observable<ImmerseResult<[String : Any], ApiError>> {
    return Observable.create({ (sub) -> Disposable in
      
      LingoHTTPSessionManager.sharedManager
        .requestObject(payload) { (response: Response<[String: Any], NSError>) in
          switch response.result {
          case .success(let result):
            sub.onNext(ImmerseResult(value: result))
          case .failure(let error):
            sub.onNext(ImmerseResult.init(error: ApiError.init("999", message: error.localizedDescription)))
          }
      }
      return Disposables.create {
        // TODO: do sth dispose
      }
    })
  }
}
