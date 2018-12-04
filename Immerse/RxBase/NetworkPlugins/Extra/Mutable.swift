//
//  Mutable.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation

public protocol Mutable {
}

public extension Mutable {
  func mutateOne<T>(transform: (inout Self) -> T) -> Self {
    var newSelf = self
    _ = transform(&newSelf)
    return newSelf
  }
  
  func mutate(transform: (inout Self) -> Void) -> Self {
    var newSelf = self
    transform(&newSelf)
    return newSelf
  }
  
  func mutate(transform: (inout Self) throws -> Void) rethrows -> Self {
    var newSelf = self
    try transform(&newSelf)
    return newSelf
  }
}
