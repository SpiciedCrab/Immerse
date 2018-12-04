//
//  PageDefinitions.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation

public struct Pageable {
  
  public var currentPage: Int = 0
  public var totalPage: Int = 0

  public init() {
    
  }
  
  public init(current: Int, total: Int) {
    currentPage = current
    totalPage = total
  }
}

public protocol PageDividing {
  var page: Pageable { get set }
}
