//
//  Result.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation


public enum ImmerseResult<T, Error: Swift.Error>: ImmerseResultProtocol, CustomStringConvertible, CustomDebugStringConvertible {
  case success(T)
  case failure(Error)
  
  // MARK: Constructors
  
  /// Constructs a success wrapping a `value`.
  public init(value: T) {
    self = .success(value)
  }
  
  /// Constructs a failure wrapping an `error`.
  public init(error: Error) {
    self = .failure(error)
  }
  
  /// Constructs a ImmerseResult from an `Optional`, failing with `Error` if `nil`.
  public init(_ value: T?, failWith: @autoclosure () -> Error) {
    self = value.map(ImmerseResult.success) ?? .failure(failWith())
  }
  
  /// Constructs a ImmerseResult from a function that uses `throw`, failing with `Error` if throws.
  public init(_ f: @autoclosure () throws -> T) {
    self.init(attempt: f)
  }
  
  /// Constructs a ImmerseResult from a function that uses `throw`, failing with `Error` if throws.
  public init(attempt f: () throws -> T) {
    do {
      self = .success(try f())
    } catch var error {
      if Error.self == AnyError.self {
        error = AnyError(error)
      }
      self = .failure(error as! Error)
    }
  }
  
  // MARK: Deconstruction
  
  /// Returns the value from `success` ImmerseResults or `throw`s the error.
  public func dematerialize() throws -> T {
    switch self {
    case let .success(value):
      return value
    case let .failure(error):
      throw error
    }
  }
  
  /// Case analysis for ImmerseResult.
  ///
  /// Returns the value produced by applying `ifFailure` to `failure` ImmerseResults, or `ifSuccess` to `success` ImmerseResults.
  public func analysis<ImmerseResult>(ifSuccess: (T) -> ImmerseResult, ifFailure: (Error) -> ImmerseResult) -> ImmerseResult {
    switch self {
    case let .success(value):
      return ifSuccess(value)
    case let .failure(value):
      return ifFailure(value)
    }
  }
  
  // MARK: Errors
  
  /// The domain for errors constructed by ImmerseResult.
  public static var errorDomain: String { return "com.antitypical.ImmerseResult" }
  
  /// The userInfo key for source functions in errors constructed by ImmerseResult.
  public static var functionKey: String { return "\(errorDomain).function" }
  
  /// The userInfo key for source file paths in errors constructed by ImmerseResult.
  public static var fileKey: String { return "\(errorDomain).file" }
  
  /// The userInfo key for source file line numbers in errors constructed by ImmerseResult.
  public static var lineKey: String { return "\(errorDomain).line" }
  
  /// Constructs an error.
  public static func error(_ message: String? = nil, function: String = #function, file: String = #file, line: Int = #line) -> NSError {
    var userInfo: [String: Any] = [
      functionKey: function,
      fileKey: file,
      lineKey: line
    ]
    
    if let message = message {
      userInfo[NSLocalizedDescriptionKey] = message
    }
    
    return NSError(domain: errorDomain, code: 0, userInfo: userInfo)
  }
  
  // MARK: CustomStringConvertible
  
  public var description: String {
    return analysis(
      ifSuccess: { ".success(\($0))" },
      ifFailure: { ".failure(\($0))" })
  }
  
  // MARK: CustomDebugStringConvertible
  
  public var debugDescription: String {
    return description
  }
}

// MARK: - Derive ImmerseResult from failable closure

public func materialize<T>(_ f: () throws -> T) -> ImmerseResult<T, AnyError> {
  return materialize(try f())
}

public func materialize<T>(_ f: @autoclosure () throws -> T) -> ImmerseResult<T, AnyError> {
  do {
    return .success(try f())
  } catch {
    return .failure(AnyError(error))
  }
}

@available(*, deprecated, message: "Use the overload which returns `ImmerseResult<T, AnyError>` instead")
public func materialize<T>(_ f: () throws -> T) -> ImmerseResult<T, NSError> {
  return materialize(try f())
}

@available(*, deprecated, message: "Use the overload which returns `ImmerseResult<T, AnyError>` instead")
public func materialize<T>(_ f: @autoclosure () throws -> T) -> ImmerseResult<T, NSError> {
  do {
    return .success(try f())
  } catch {
    // This isn't great, but it lets us maintain compatibility until this deprecated
    // method can be removed.
    #if _runtime(_ObjC)
    return .failure(error as NSError)
    #else
    // https://github.com/apple/swift-corelibs-foundation/blob/swift-3.0.2-RELEASE/Foundation/NSError.swift#L314
    let userInfo = _swift_Foundation_getErrorDefaultUserInfo(error) as? [String: Any]
    let nsError = NSError(domain: error._domain, code: error._code, userInfo: userInfo)
    return .failure(nsError)
    #endif
  }
}

// MARK: - Cocoa API conveniences

#if !os(Linux)

/// Constructs a `ImmerseResult` with the ImmerseResult of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns an object or `nil` + an error, by reference. e.g.:
///
///     ImmerseResult.try { NSData(contentsOfURL: URL, options: .dataReadingMapped, error: $0) }
@available(*, deprecated, message: "This will be removed in ImmerseResult 4.0. Use `ImmerseResult.init(attempt:)` instead. See https://github.com/antitypical/ImmerseResult/issues/85 for the details.")
public func `try`<T>(_ function: String = #function, file: String = #file, line: Int = #line, `try`: (NSErrorPointer) -> T?) -> ImmerseResult<T, NSError> {
  var error: NSError?
  return `try`(&error).map(ImmerseResult.success) ?? .failure(error ?? ImmerseResult<T, NSError>.error(function: function, file: file, line: line))
}

/// Constructs a `ImmerseResult` with the ImmerseResult of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns a `Bool` + an error, by reference. e.g.:
///
///     ImmerseResult.try { NSFileManager.defaultManager().removeItemAtURL(URL, error: $0) }
@available(*, deprecated, message: "This will be removed in ImmerseResult 4.0. Use `ImmerseResult.init(attempt:)` instead. See https://github.com/antitypical/ImmerseResult/issues/85 for the details.")
public func `try`(_ function: String = #function, file: String = #file, line: Int = #line, `try`: (NSErrorPointer) -> Bool) -> ImmerseResult<(), NSError> {
  var error: NSError?
  return `try`(&error) ?
    .success(())
    :  .failure(error ?? ImmerseResult<(), NSError>.error(function: function, file: file, line: line))
}

#endif

// MARK: - ErrorConvertible conformance

extension NSError: ErrorConvertible {
  public static func error(from error: Swift.Error) -> Self {
    func cast<T: NSError>(_ error: Swift.Error) -> T {
      return error as! T
    }
    
    return cast(error)
  }
}

// MARK: - Errors

/// An “error” that is impossible to construct.
///
/// This can be used to describe `ImmerseResult`s where failures will never
/// be generated. For example, `ImmerseResult<Int, NoError>` describes a ImmerseResult that
/// contains an `Int`eger and is guaranteed never to be a `failure`.
public enum NoError: Swift.Error, Equatable {
  public static func ==(lhs: NoError, rhs: NoError) -> Bool {
    return true
  }
}

/// A type-erased error which wraps an arbitrary error instance. This should be
/// useful for generic contexts.
public struct AnyError: Swift.Error {
  /// The underlying error.
  public let error: Swift.Error
  
  public init(_ error: Swift.Error) {
    if let anyError = error as? AnyError {
      self = anyError
    } else {
      self.error = error
    }
  }
}

extension AnyError: ErrorConvertible {
  public static func error(from error: Error) -> AnyError {
    return AnyError(error)
  }
}

extension AnyError: CustomStringConvertible {
  public var description: String {
    return String(describing: error)
  }
}

// There appears to be a bug in Foundation on Linux which prevents this from working:
// https://bugs.swift.org/browse/SR-3565
// Don't forget to comment the tests back in when removing this check when it's fixed!
#if !os(Linux)

extension AnyError: LocalizedError {
  public var errorDescription: String? {
    return error.localizedDescription
  }
  
  public var failureReason: String? {
    return (error as? LocalizedError)?.failureReason
  }
  
  public var helpAnchor: String? {
    return (error as? LocalizedError)?.helpAnchor
  }
  
  public var recoverySuggestion: String? {
    return (error as? LocalizedError)?.recoverySuggestion
  }
}

#endif

// MARK: - migration support
extension ImmerseResult {
  @available(*, unavailable, renamed: "success")
  public static func Success(_: T) -> ImmerseResult<T, Error> {
    fatalError()
  }
  
  @available(*, unavailable, renamed: "failure")
  public static func Failure(_: Error) -> ImmerseResult<T, Error> {
    fatalError()
  }
}

extension NSError {
  @available(*, unavailable, renamed: "error(from:)")
  public static func errorFromErrorType(_ error: Swift.Error) -> Self {
    fatalError()
  }
}

import Foundation