//
//  ResultProtocol.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation
public protocol ImmerseResultProtocol {
  associatedtype Value
  associatedtype Error: Swift.Error
  
  /// Constructs a successful ImmerseResult wrapping a `value`.
  init(value: Value)
  
  /// Constructs a failed ImmerseResult wrapping an `error`.
  init(error: Error)
  
  /// Case analysis for ImmerseResultProtocol.
  ///
  /// Returns the value produced by appliying `ifFailure` to the error if self represents a failure, or `ifSuccess` to the ImmerseResult value if self represents a success.
  func analysis<U>(ifSuccess: (Value) -> U, ifFailure: (Error) -> U) -> U
  
  /// Returns the value if self represents a success, `nil` otherwise.
  ///
  /// A default implementation is provided by a protocol extension. Conforming types may specialize it.
  var value: Value? { get }
  
  /// Returns the error if self represents a failure, `nil` otherwise.
  ///
  /// A default implementation is provided by a protocol extension. Conforming types may specialize it.
  var error: Error? { get }
}

public extension ImmerseResultProtocol {
  
  /// Returns the value if self represents a success, `nil` otherwise.
  public var value: Value? {
    return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
  }
  
  /// Returns the error if self represents a failure, `nil` otherwise.
  public var error: Error? {
    return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
  }
  
  /// Returns a new ImmerseResult by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
  public func map<U>(_ transform: (Value) -> U) -> ImmerseResult<U, Error> {
    return flatMap { .success(transform($0)) }
  }
  
  /// Returns the ImmerseResult of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
  public func flatMap<U>(_ transform: (Value) -> ImmerseResult<U, Error>) -> ImmerseResult<U, Error> {
    return analysis(
      ifSuccess: transform,
      ifFailure: ImmerseResult<U, Error>.failure)
  }
  
  /// Returns a ImmerseResult with a tuple of the receiver and `other` values if both
  /// are `Success`es, or re-wrapping the error of the earlier `Failure`.
  public func fanout<R: ImmerseResultProtocol>(_ other: @autoclosure () -> R) -> ImmerseResult<(Value, R.Value), Error>
    where Error == R.Error {
      return self.flatMap { left in other().map { right in (left, right) } }
  }
  
  /// Returns a new ImmerseResult by mapping `Failure`'s values using `transform`, or re-wrapping `Success`es’ values.
  public func mapError<Error2>(_ transform: (Error) -> Error2) -> ImmerseResult<Value, Error2> {
    return flatMapError { .failure(transform($0)) }
  }
  
  /// Returns the ImmerseResult of applying `transform` to `Failure`’s errors, or re-wrapping `Success`es’ values.
  public func flatMapError<Error2>(_ transform: (Error) -> ImmerseResult<Value, Error2>) -> ImmerseResult<Value, Error2> {
    return analysis(
      ifSuccess: ImmerseResult<Value, Error2>.success,
      ifFailure: transform)
  }
  
  /// Returns a new ImmerseResult by mapping `Success`es’ values using `success`, and by mapping `Failure`'s values using `failure`.
  public func bimap<U, Error2>(success: (Value) -> U, failure: (Error) -> Error2) -> ImmerseResult<U, Error2> {
    return analysis(
      ifSuccess: { .success(success($0)) },
      ifFailure: { .failure(failure($0)) }
    )
  }
}

public extension ImmerseResultProtocol {
  
  // MARK: Higher-order functions
  
  /// Returns `self.value` if this ImmerseResult is a .Success, or the given value otherwise. Equivalent with `??`
  public func recover(_ value: @autoclosure () -> Value) -> Value {
    return self.value ?? value()
  }
  
  /// Returns this ImmerseResult if it is a .Success, or the given ImmerseResult otherwise. Equivalent with `??`
  public func recover(with ImmerseResult: @autoclosure () -> Self) -> Self {
    return analysis(
      ifSuccess: { _ in self },
      ifFailure: { _ in ImmerseResult() })
  }
}

/// Protocol used to constrain `tryMap` to `ImmerseResult`s with compatible `Error`s.
public protocol ErrorConvertible: Swift.Error {
  static func error(from error: Swift.Error) -> Self
}

public extension ImmerseResultProtocol where Error: ErrorConvertible {
  
  /// Returns the ImmerseResult of applying `transform` to `Success`es’ values, or wrapping thrown errors.
  public func tryMap<U>(_ transform: (Value) throws -> U) -> ImmerseResult<U, Error> {
    return flatMap { value in
      do {
        return .success(try transform(value))
      } catch {
        let convertedError = Error.error(from: error)
        // Revisit this in a future version of Swift. https://twitter.com/jckarter/status/672931114944696321
        return .failure(convertedError)
      }
    }
  }
}
// MARK: - Operators
infix operator &&& : LogicalConjunctionPrecedence

/// Returns a ImmerseResult with a tuple of `left` and `right` values if both are `Success`es, or re-wrapping the error of the earlier `Failure`.
@available(*, deprecated, renamed: "ImmerseResultProtocol.fanout(self:_:)")
public func &&& <L: ImmerseResultProtocol, R: ImmerseResultProtocol> (left: L, right: @autoclosure () -> R) -> ImmerseResult<(L.Value, R.Value), L.Error>
  where L.Error == R.Error {
    return left.fanout(right)
}

precedencegroup ChainingPrecedence {
  associativity: left
  higherThan: TernaryPrecedence
}

infix operator >>- : ChainingPrecedence

/// Returns the ImmerseResult of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
///
/// This is a synonym for `flatMap`.
@available(*, deprecated, renamed: "ImmerseResultProtocol.flatMap(self:_:)")
public func >>- <T: ImmerseResultProtocol, U> (ImmerseResult: T, transform: (T.Value) -> ImmerseResult<U, T.Error>) -> ImmerseResult<U, T.Error> {
  return ImmerseResult.flatMap(transform)
}

/// Returns `true` if `left` and `right` are both `Success`es and their values are equal, or if `left` and `right` are both `Failure`s and their errors are equal.
public func == <T: ImmerseResultProtocol> (left: T, right: T) -> Bool
  where T.Value: Equatable, T.Error: Equatable {
    if let left = left.value, let right = right.value {
      return left == right
    } else if let left = left.error, let right = right.error {
      return left == right
    }
    return false
}

/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
public func != <T: ImmerseResultProtocol> (left: T, right: T) -> Bool
  where T.Value: Equatable, T.Error: Equatable {
    return !(left == right)
}

/// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
public func ?? <T: ImmerseResultProtocol> (left: T, right: @autoclosure () -> T.Value) -> T.Value {
  return left.recover(right())
}

/// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
public func ?? <T: ImmerseResultProtocol> (left: T, right: @autoclosure () -> T) -> T {
  return left.recover(with: right())
}

// MARK: - migration support
@available(*, unavailable, renamed: "ImmerseResultProtocol")
public typealias ImmerseResultType = ImmerseResultProtocol

@available(*, unavailable, renamed: "Error")
public typealias ImmerseResultErrorType = Swift.Error

@available(*, unavailable, renamed: "ErrorConvertible")
public typealias ErrorTypeConvertible = ErrorConvertible

@available(*, deprecated, renamed: "ErrorConvertible")
public protocol ErrorProtocolConvertible: ErrorConvertible {}

extension ImmerseResultProtocol {
  @available(*, unavailable, renamed: "recover(with:)")
  public func recoverWith(_ ImmerseResult: @autoclosure () -> Self) -> Self {
    fatalError()
  }
}

extension ErrorConvertible {
  @available(*, unavailable, renamed: "error(from:)")
  public static func errorFromErrorType(_ error: Swift.Error) -> Self {
    fatalError()
  }
}
