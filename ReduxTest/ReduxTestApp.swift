//
//  ReduxTestApp.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/7.
//

import SwiftUI

@main
struct ReduxTestApp: App {
    // 保证唯一性，且方便定义派生Store
    static let mainStore = Store(intialState: AppState(words: []), enivronment: AppEnvironment.share,reducer:appReducer)
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


