//
//  Model.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/7.
//

import Combine
import Foundation

struct AppState: Equatable {
    var words: [String] = []
    var name: String = ""
    var itemState = ItemState(itemName: "")
    var memoState = MemoState(memoName: "")
}

struct ItemState: Equatable {
    var itemName: String
}

struct MemoState: Equatable {
    var memoName: String
}

enum AppAction {
    case qureyWords(qurey: String)
    case setWords(words: [String])
    case itemAction(action: ItemAction)
    case memoAction(action: MemoAction)
}

enum ItemAction {
    case setName(name: String)
}

enum MemoAction {
    case setMemo(name: String)
}

struct AppEnvironment {
    static let share = AppEnvironment()
    func getWords(qurey: String) -> AnyPublisher<AppAction, Never> {
        return Just(.setWords(words: ["fat", "name", "bob"])).eraseToAnyPublisher()
    }
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer { state, action, environment in
    switch action {
    case .qureyWords(let qurey):
        return environment.getWords(qurey: qurey)
    case .setWords(let words):
        state.words = words
    case .itemAction(let itemAction):
        let effect = itemReducer(&state.itemState, itemAction, environment)
        return effect
            .map(AppAction.itemAction)
            .eraseToAnyPublisher()
    case .memoAction(let memoAction):
        let effect = memoReducer(&state.memoState, memoAction, environment)
        return effect
            .map(AppAction.memoAction)
            .eraseToAnyPublisher()
    }
    return Empty(completeImmediately: true).eraseToAnyPublisher()
}
.signpost()

let itemReducer: Reducer<ItemState, ItemAction, AppEnvironment> = Reducer { state, action, _ in
    switch action {
    case .setName(let name):
        state.itemName = name
    }
    return Empty(completeImmediately: true).eraseToAnyPublisher()
}

let memoReducer: Reducer<MemoState, MemoAction, AppEnvironment> = Reducer { state, action, _ in
    switch action {
    case .setMemo(let name):
        state.memoName = name
    }
    return Empty(completeImmediately: true).eraseToAnyPublisher()
}

//方便项目改名称
typealias MyApp = ReduxTestApp

let rootStore = MyApp.mainStore
let itemStore = MyApp.mainStore.derived(derivedState: \.itemState, embedAction: AppAction.itemAction)
let memoStore = MyApp.mainStore.derived(derivedState: \.memoState, embedAction: AppAction.memoAction)

// For Test, Can mix any state value in a new state struct 
let otherStore = MyApp.mainStore.derived(derivedState: { appstate -> OtherState in
    return OtherState(words: appstate.words,name:appstate.name)
})

struct OtherState:Equatable{
    var words:[String]
    var name:String
}
