//
//  LingomeViewRx.swift
//  LingoStudy
//
//  Created by CatHarly on 2018/9/12.
//  Copyright © 2018年 LLS iOS Team. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import LLSFoundation
import LLSUI

extension Reactive where Base : UIBarButtonItem {
  var tintColor: Binder<UIColor> {
    
    return Binder(self.base, binding: { (base, color) in
      base.tintColor = color
    })
  }
}

extension Reactive where Base : UIView {
  var backgroundColor: Binder<UIColor> {
    
    return Binder(self.base, binding: { (base, color) in
      base.backgroundColor = color
    })
  }
}

extension Reactive where Base : UITableView {
  var scrollToPath: Binder<IndexPath> {
    
    return Binder(self.base, binding: { (base, path) in
      base.scrollToRow(at: path, at: UITableViewScrollPosition.middle, animated: true)
    })
  }
  
  var selectPath: Binder<IndexPath> {
    
    return Binder(self.base, binding: { (base, path) in
      base.selectRow(at: path, animated: true, scrollPosition: UITableViewScrollPosition.top)
    })
  }
}


extension Reactive where Base : UIView {
  var showInfoMessage: Binder<String> {
    
    return Binder(self.base, binding: { (_, msg) in
      SVProgressHUD.showInfo(withStatus: msg)
    })
  }
  
  var showSuccessMessage: Binder<String> {
    
    return Binder(self.base, binding: { (_, msg) in
      SVProgressHUD.showSuccess(withStatus: msg)
    })
  }
  
  var showError: Binder<RxError> {
    return Binder(self.base, binding: { (_, error) in
      SVProgressHUD.showError(withStatus: error.apiError.message)
    })
  }
  
  var showErrorMessage: Binder<String> {
    return Binder(self.base, binding: { (_, msg) in
      SVProgressHUD.showError(withStatus: msg)
    })
  }
}
