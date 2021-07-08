//
//  Store.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/8.
//

import Combine
import Foundation

class Store<State, Action, Environment>: ObservableObject {
    init(intialState: State, enivronment: Environment, reducer: Reducer<State, Action, Environment>, subscriptionQueue: DispatchQueue = .init(label: "com.fatbobman.reduxtest")) {
        state = intialState
        environment = enivronment
        self.reducer = reducer
        queue = subscriptionQueue
    }

    @Published private(set) var state: State
    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>
    private var cancllables: [UUID: AnyCancellable] = [:]
    private let queue: DispatchQueue

    func send(_ action: Action) {
        let effect = reducer(&state, action, environment)
        var didComplete = false
        let uuid = UUID()

        let cancellable = effect
            .subscribe(on: queue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    self?.cancllables[uuid] = nil
                },
                receiveValue: { [weak self] in
                    self?.send($0)
                }
            )

        if !didComplete {
            cancllables[uuid] = cancellable
        }
    }

    /// 将Store派生成新的Store
    ///
    /// ```swift
    /// struct AppState:Equatable{
    ///     var words:[String] = []
    ///     var itemState = ItemState(itemName: "")
    ///     var memoState = MemoState(memoName: "")
    /// }
    ///
    /// struct ItemState:Equatable{
    ///     var itemName:String
    ///  }
    ///
    /// struct MemoState:Equatable{
    ///     var memoName:String
    /// }
    ///
    /// enum AppAction{
    ///     case qureyWords(qurey:String)
    ///     case setWords(words:[String])
    ///     case itemAction(action:ItemAction)
    ///     case memoAction(action:MemoAction)
    /// }
    ///
    /// enum ItemAction{
    ///     case setName(name:String)
    /// }
    ///
    /// enum MemoAction{
    ///     case setMemo(name:String)
    /// }
    ///
    /// let store = Store()
    /// let itemStore = store.derived(derivedState: \.itemState, embedAction: AppAction.itemAction)
    /// ```
    ///
    /// - Parameters:
    ///   - derivedState: 将要派生的部分State，在原始State中，将针对某个特定功能的数据汇总到一起，定义成一个子State集，方便派生.
    ///   - embedAction: 将要派生的Action，在原始的Action VS，将针对某个特定功能的Action汇总到一起，定义成一个子Action集，方便派生.
    /// - Returns: 一个只包含部分State和Action的Store
    func derived<DerivedState: Equatable, ExractedAction>(
        derivedState: @escaping (State) -> DerivedState,
        embedAction: @escaping (ExractedAction) -> Action
    ) -> Store<DerivedState, ExractedAction, Environment> {
        let store = Store<DerivedState, ExractedAction, Environment>(
            intialState: derivedState(state),
            enivronment: environment,
            reducer: Reducer { _, action, _ in
                self.send(embedAction(action))
                return Empty().eraseToAnyPublisher()
            }
        )
        $state
            .subscribe(on:queue)
            .map(derivedState)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &store.$state)

        return store
    }

    /// 派生一个新的Store，只暴露一部分State。但是还是使用和当前Store一样的Action和Reducer
    ///
    /// - Parameters:
    ///   - derivedState: 将要派生的部分State，在原始State中，将针对某个特定功能的数据汇总到一起，定义成一个子State集，方便派生.
    /// - Returns: 一个只包含部分State的Store
    func derived<DerivedState:Equatable>(
        derivedState: @escaping (State) -> DerivedState
    ) -> Store<DerivedState,Action,Environment>{
        let store = Store<DerivedState,Action,Environment>(
            intialState: derivedState(state),
            enivronment: environment,
            reducer: Reducer{ _,action,_ in
                self.send(action)
                return Empty().eraseToAnyPublisher()
            }
        )
            $state
                .subscribe(on:queue)
                .map(derivedState)
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: &store.$state)
            return store
    }
}

import SwiftUI

extension Store {
    /// 为指定的State keyPath创建binding
    ///
    ///  sample code:
    ///
    /// ```swift
    /// struct State{
    ///    var name:String
    ///    var age:Int
    /// }
    /// private var words: Binding<String>
    ///  {
    ///    store.binding(
    ///    for: \.name,
    ///    toAction: {.setName(name: $0)})
    ///  }
    /// ```
    func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        toAction: @escaping (Value) -> Action
    ) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(toAction($0)) }
        )
    }
}
