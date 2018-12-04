//
//  LingomeDebugRx.swift
//  LingoStudy
//
//  Created by CatHarly on 2018/9/12.
//  Copyright © 2018年 LLS iOS Team. All rights reserved.
//

import Foundation
import Foundation
import RxCocoa
import RxSwift
import LLSFoundation
import LLSUI

extension Observable {
  func showStatus(message: String) -> Observable {
    return self.do(onNext: { (_) in
      SVProgressHUD.showInfo(withStatus: message)
    })
  }
}
