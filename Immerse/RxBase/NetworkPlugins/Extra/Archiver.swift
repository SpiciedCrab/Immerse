////
////  Archiver.swift
////  Immerse
////
////  Created by CatHarly on 2018/9/3.
////  Copyright © 2018年 Harly. All rights reserved.
////
//
//import Foundation
//import protocol Swift.Decodable
//
public enum RxBricks<Element> {
  case loading
  case finished(result : Element)
  case error
}

public typealias ModelType = Codable

extension JSONDecoder {
  /**use this instead of the the default one to */
  open class func mainDecoder() -> JSONDecoder {
    return JSONDecoder.lingoDecoder()
  }

//  open func decode<T>(_ type: T.Type, fromAny representation: Any) -> T? where T: Decodable {
//
//    if !JSONSerialization.isValidJSONObject(representation) {
//      return nil
//    }
//
//    do {
//      let jsonData = try JSONSerialization.data(withJSONObject: representation)
//      return try decode(type.self, from: jsonData)
//    } catch {
//      return nil
//    }
//  }
//
//  open func decodeArray<T>(_ type: T.Type, fromAny representation: Any) -> [T] where T: Decodable {
//
//    if !JSONSerialization.isValidJSONObject(representation) {
//      return [T]()
//    }
//
//    do {
//      let jsonData = try JSONSerialization.data(withJSONObject: representation)
//      return try decode([T].self, from: jsonData)
//    } catch {
//      return [T]()
//    }
//  }
}
