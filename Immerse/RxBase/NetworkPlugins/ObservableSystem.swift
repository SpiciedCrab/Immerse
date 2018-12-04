//
//  ObservableSystem.swift
//  Immerse
//
//  Created by CatHarly on 2018/9/3.
//  Copyright © 2018年 Harly. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public protocol Statable {
  
  var isLoading: Bool { get set }
  
  var isFailed: Bool { get }
}


extension Observable {
  public static func system<State>(
    _ initialState: State,
    accumulator: @escaping (State, Element) -> State,
    scheduler: SchedulerType,
    feedback: (Observable<State>) -> Observable<Element>...
    ) -> Observable<State> {
    return Observable<State>.deferred {
      let replaySubject = ReplaySubject<State>.create(bufferSize: 1)
      
      let inputs: Observable<Element> = Observable.merge(feedback.map { $0(replaySubject.asObservable()) })
        .observeOn(scheduler)
      
      return inputs.scan(initialState, accumulator: accumulator)
        .startWith(initialState)
        .do(onNext: { output in
          replaySubject.onNext(output)
        })
    }
  }
}

extension SharedSequence {
  
  public static func system<State: Statable>(
    _ initialState: State,
    accumulator: @escaping (State, Element) -> State,
    feedback: (SharedSequence<S, State>) -> SharedSequence<S, Element>...
    ) -> SharedSequence<S, State> {
    return SharedSequence<S, State>.deferred {
      let replaySubject = ReplaySubject<State>.create(bufferSize: 1)
      
      let outputDriver = replaySubject.asSharedSequence(onErrorDriveWith: SharedSequence<S, State>.empty())
      
      let inputs = SharedSequence.merge(feedback.map { $0(outputDriver) })
      
      return inputs.scan(initialState, accumulator: accumulator)
        .startWith(initialState)
        .do(onNext: { output in
          replaySubject.onNext(output)
        })
    }
  }
}
