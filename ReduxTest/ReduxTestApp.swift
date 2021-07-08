//
//  ReduxTestApp.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/7.
//

import SwiftUI

@main
struct ReduxTestApp: App {
    static let mainStore = Store(intialState: AppState(words: []), enivronment: AppEnvironment.share,reducer:appReducer)
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

typealias MyApp = ReduxTestApp

let rootStore = MyApp.mainStore
let itemStore = MyApp.mainStore.derived(derivedState: \.itemState, embedAction: AppAction.itemAction)
let memoStore = MyApp.mainStore.derived(derivedState: \.memoState, embedAction: AppAction.memoAction)
let otherStore = MyApp.mainStore.derived(derivedState: { appstore -> OtherState in
    return OtherState(words: appstore.words)
})

struct OtherState:Equatable{
    var words:[String]
}
