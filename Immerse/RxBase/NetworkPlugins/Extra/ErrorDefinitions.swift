//
//  ErrorDefinitions.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation
public let emptyMessageErrorCode = "-698"

// MARK: - RxMogo自定义Error
public struct RxError {
  /// 标识
  public var identifier: String?
  
  /// Error
  public var apiError: ApiError
  
  /// 通过一个message生成一个error
  ///
  /// - Parameter message: message
  /// - Returns: error
  public static func buildErrorWithMessage(message: String) -> RxError {
    return RxError(identifier: nil, apiError: ApiError("-99", message: message))
  }
  
  /// 给数据为空特地做的error
  ///
  /// - Parameter message: message
  /// - Returns: error
  public static func buildEmptyMessage(message: String) -> RxError {
    return RxError(identifier: nil, apiError: ApiError(emptyMessageErrorCode, message: message))
  }
  
  /// 生成个错误
  ///
  /// - Parameters:
  ///   - identifier: identifier
  ///   - error: 错误
  public static func buildError(identifier: String?,
                                error: ApiError) -> RxError {
    return RxError(identifier: identifier, apiError: error)
  }
}

/// Error message type
public struct APIErrorDefinition {
  
  public enum ErrorType: Int {
    case relyBackstage = 1      // Assign error code and description from backstage
    case custom                 // Custom error code and description, this description direct assign to MGAPIError.instance.message
    case buildRequest           // Request generate error code and description, this description not assign MGAPIError
    case connection
    case processResponse
    case mockPhases
  }
  
  public var code: Int
  public var description: String
  public var type: ErrorType = .relyBackstage
}

/// API Error
public struct ApiError: Error {
  
  public var code: String?
  public var message: String?
  public var description: APIErrorDefinition
  
  private static var codePlaceholder = 0
  private static var descriptionPlaceholder = "服务器采蘑菇去咯 >_<"
  
  /// Maybe you hope this Error should carry a object of any type
  public var object: Any?
  
  /// Initial custom error
  ///
  /// - Parameters:
  ///   - code: Error code
  ///   - message: Error message
  public init(_ code: String?, message: String?) {
    self.code = code
    self.message = message
    
    let codeTemp = Int(code ?? "0") ?? ApiError.codePlaceholder
    let des = message ?? "后台返回数据中未找到 Message 信息"
    self.description = APIErrorDefinition(code: codeTemp, description: des, type: .custom)
  }
  
  /// Initial error from local
  /// If you want build a custom error, you shoud use this method
  ///
  /// - Parameters:
  ///   - type: Error type
  ///   - code: Error code
  ///   - message: Error message
  public init(_ type: APIErrorDefinition.ErrorType, content: (code: Int, description: String)) {
    self.code = "\(content.code)"
    switch type {
    case .custom, .relyBackstage:
      self.message = content.description
    default:
      self.message = ApiError.descriptionPlaceholder
    }
    self.description = APIErrorDefinition(code: content.code, description: content.description, type: type)
  }
}
