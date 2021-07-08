//
//  Reducer.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/8.
//

import Combine
import Foundation

struct Prism<Source, Target> {
    let embed: (Target) -> Source
    let extract: (Source) -> Target?
}

struct Reducer<State, Action, Environment> {
    let reduce: (inout State, Action, Environment) -> AnyPublisher<Action, Never>

    func callAsFunction(
        _ state: inout State,
        _ action: Action,
        _ environment: Environment
    ) -> AnyPublisher<Action, Never> {
        reduce(&state, action, environment)
    }

    func indexed<IndexedState, IndexedAction, IndexedEnvironment, Key>(
        keyPath: WritableKeyPath<IndexedState, [Key: State]>,
        prism: Prism<IndexedAction, (Key, Action)>,
        extractEnvironment: @escaping (IndexedEnvironment) -> Environment
    ) -> Reducer<IndexedState, IndexedAction, IndexedEnvironment> {
        .init { state, action, environment in
            guard let (index, action) = prism.extract(action) else {
                return Empty().eraseToAnyPublisher()
            }
            let environment = extractEnvironment(environment)
            return self
                .optional()
                .reduce(&state[keyPath: keyPath][index], action, environment)
                .map { prism.embed((index, $0)) }
                .eraseToAnyPublisher()
        }
    }

    func indexed<IndexedState, IndexedAction, IndexedEnvironment>(
        keyPath: WritableKeyPath<IndexedState, [State]>,
        prism: Prism<IndexedAction, (Int, Action)>,
        extractEnvironment: @escaping (IndexedEnvironment) -> Environment
    ) -> Reducer<IndexedState, IndexedAction, IndexedEnvironment> {
        .init { state, action, environment in
            guard let (index, action) = prism.extract(action) else {
                return Empty().eraseToAnyPublisher()
            }
            let environment = extractEnvironment(environment)
            return self
                .reduce(&state[keyPath: keyPath][index], action, environment)
                .map { prism.embed((index, $0)) }
                .eraseToAnyPublisher()
        }
    }

    /// 允许可选的State值
    func optional() -> Reducer<State?, Action, Environment> {
        .init { state, action, environment in
            if state != nil {
                return self(&state!, action, environment)
            } else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
        }
    }

    func lift<LiftedState, LiftedAction, LiftedEnvironment>(
        keyPath: WritableKeyPath<LiftedState, State>,
        prism: Prism<LiftedAction, Action>,
        extractEnvironment: @escaping (LiftedEnvironment) -> Environment
    ) -> Reducer<LiftedState, LiftedAction, LiftedEnvironment> {
        .init { state, action, environment in
            let environment = extractEnvironment(environment)
            guard let action = prism.extract(action) else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            let effect = self(&state[keyPath: keyPath], action, environment)
            return effect.map(prism.embed).eraseToAnyPublisher()
        }
    }

    static func combine(_ reducers: Reducer...) -> Reducer {
        .init { state, action, environment in
            let effects = reducers.compactMap { $0(&state, action, environment) }
            return Publishers.MergeMany(effects).eraseToAnyPublisher()
        }
    }
}

import os.log

extension Reducer {
    /// 性能调试输出，对于判断耗时的action，非常有帮助。使用Instrumens进行调试，创建空模版，添加os_signpost
    /// https://everettjf.github.io/2018/08/13/os-signpost-tutorial/
    func signpost(log: OSLog = OSLog(subsystem: "com.fatbobman.reduxTest", category: "Reducer")) -> Reducer {
        .init { state, action, environment in
            let actionString = String(reflecting: action)
            os_signpost(.event, log: log, name: "Action", "%{public}@", actionString)
            os_signpost(.begin, log: log, name: "Action", "%{public}@", actionString)
            let effect = self.reduce(&state, action, environment)
            os_signpost(.end, log: log, name: "Action", "%{public}@", actionString)
            return effect
        }
    }

    func log(log: OSLog = OSLog(subsystem: "com.fatbobman.reduxTest", category: "Reducer")) -> Reducer {
        .init { state, action, environment in
            os_log(.default, log: log, "Action %s", String(reflecting: action))
            let effect = self.reduce(&state, action, environment)
            os_log(.default, log: log, "State %s", String(reflecting: state))
            return effect
        }
    }
}
