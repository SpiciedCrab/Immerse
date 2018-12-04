//
//  VersionStruct.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation

public class Unique: NSObject {
  
}

public struct Version<Value>: Hashable {
  
  private let _unique: Unique
  public let value: Value
  
  public init(_ value: Value) {
    self._unique = Unique()
    self.value = value
  }
  
  public var hashValue: Int {
    return self._unique.hash
  }
  
  public static func == (lhs: Version<Value>, rhs: Version<Value>) -> Bool {
    return lhs._unique === rhs._unique
  }
}
extension Version {
  public func mutate(transform: (inout Value) -> Void) -> Version<Value> {
    var newSelf = self.value
    transform(&newSelf)
    return Version(newSelf)
  }
  
  public func mutate(transform: (inout Value) throws -> Void) rethrows -> Version<Value> {
    var newSelf = self.value
    try transform(&newSelf)
    return Version(newSelf)
  }
}
