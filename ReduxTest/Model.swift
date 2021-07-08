//
//  Model1.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/7.
//

import Foundation
import Combine

struct AppState:Equatable{
    var words:[String] = []
    var itemState = ItemState(itemName: "")
    var memoState = MemoState(memoName: "")
}

struct ItemState:Equatable{
    var itemName:String
}

struct MemoState:Equatable{
    var memoName:String
}

enum AppAction{
    case qureyWords(qurey:String)
    case setWords(words:[String])
    case itemAction(action:ItemAction)
    case memoAction(action:MemoAction)
}


enum ItemAction{
    case setName(name:String)
}

enum MemoAction{
    case setMemo(name:String)
}

struct AppEnvironment{
    static let share = AppEnvironment()
    func getWords(qurey:String) -> AnyPublisher<AppAction,Never>{
        return Just(.setWords(words:["fat","name","bob"])).eraseToAnyPublisher()
    }
}

typealias Reducer<State,Action,Environment> = (inout State,Action,Environment) -> AnyPublisher<Action,Never>?

func appReducer(state:inout AppState,action:AppAction,environment:AppEnvironment) -> AnyPublisher<AppAction,Never>?{
    switch action{
        case .qureyWords(let qurey):
            return environment.getWords(qurey: qurey)
        case .setWords(let words):
            state.words = words
        case .itemAction(let itemAction):
            guard let effect = itemReducer(state: &state.itemState, action: itemAction,environment: environment) else {return nil}
            return effect
                .map(AppAction.itemAction)
                .eraseToAnyPublisher()
        case .memoAction(let memoAction):
            guard let effect = memoReducer(state: &state.memoState,action:memoAction,environment: environment) else {return nil}
            return effect
                .map(AppAction.memoAction)
                .eraseToAnyPublisher()
    }
    return nil
}



func itemReducer(state:inout ItemState,action:ItemAction,environment:AppEnvironment) -> AnyPublisher<ItemAction,Never>?{
    switch action{
        case .setName(let name):
            state.itemName = name
    }
    return nil
}

func memoReducer(state:inout MemoState,action:MemoAction,environment:AppEnvironment) -> AnyPublisher<MemoAction,Never>?{
    switch action{
        case .setMemo(let name):
            state.memoName = name
    }
    return nil
}

class Store<State,Action,Environment>:ObservableObject{
    init(intialState:State, enivronment: Environment, reducer: @escaping Reducer<State, Action, Environment>) {
        self.state = intialState
        self.environment = enivronment
        self.reducer = reducer
    }

    @Published private(set) var state:State
    private let environment:Environment
    private let reducer:Reducer<State,Action,Environment>
    private var cancllables:Set<AnyCancellable> = []

    func send(action:Action) {
        guard let effect = reducer(&state,action,environment) else {return}
        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                self.send(action: $0)
            })
            .store(in: &cancllables)
    }

    func derived<DerivedState:Equatable,ExractedAction>(
        derivedState:@escaping (State) -> DerivedState,
        embedAction:@escaping (ExractedAction) -> Action
    ) -> Store<DerivedState,ExractedAction,Environment>{
        let store = Store<DerivedState,ExractedAction,Environment>(
            intialState: derivedState(state),
            enivronment: environment,
            reducer: { _,action,_ in
                self.send(action: embedAction(action))
                return Empty().eraseToAnyPublisher()
            }
        )
        $state
            .map(derivedState)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &store.$state)

        return store
    }

}


