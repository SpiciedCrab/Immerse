//
//  SectionableRxDataSources.swift
//  LingoStudy
//
//  Created by CatHarly on 2018/9/11.
//  Copyright © 2018年 LLS iOS Team. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import RxDataSources

//可动画的section
public typealias SectionAnimatable = IdentifiableType & Equatable
public class AnimatableSection<ItemElement: SectionAnimatable>: AnimatableSectionModelType {
  public typealias Identity = Int
  public typealias Item = ItemElement
  
  public var items: [ItemElement] = []
  public var identity: Int {
    return header.hashValue
  }
  var header: String = ""
  init() { }
  public required init(original: AnimatableSection, items: [Item]) {
    self.header = original.header
    self.items = items
  }
  public convenience init(header: String, items: [Item]) {
    let section = AnimatableSection<Item>()
    section.header = header
    section.items = items
    self.init(original: section, items: items)
    self.header = header
  }
}
/// MGSection model
public class LingoSection<ItemElement>: SectionModelType {
  
  public typealias Item = ItemElement
  
  public var header: String = ""
  
  public var items: [Item] = []
  
  init() {
    
  }
  
  public required init(original: LingoSection, items: [Item]) {
    self.header = original.header
    self.items = items
  }
  
  /// 初始化调用我就行了
  ///
  /// - Parameters:
  ///   - header: header string
  ///   - items: items
  public convenience init(header: String, items: [Item]) {
    let section = LingoSection<Item>()
    section.header = header
    section.items = items
    
    self.init(original: section, items: items)
    self.header = header
    
  }
}

/// 复杂的sectionModel
public class ComplexSection<SectionElement, ItemElement>: SectionModelType {
  public var items: [ItemElement] = [ItemElement]()
  
  public typealias Item = ItemElement
  public var section: SectionElement?
  
  init() {
    //
  }
  public required init(original: ComplexSection, items: [ComplexSection.Item]) {
    self.section = original.section
    self.items = items
  }
  public convenience init(section: SectionElement, items: [ComplexSection.Item]) {
    let complexSection = ComplexSection<SectionElement, Item>()
    complexSection.section = section
    complexSection.items = items
    self.init(original: complexSection, items: items)
    self.section = section
  }
}
