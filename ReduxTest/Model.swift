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

//typealias Reducer<State,Action,Environment> = (inout State,Action,Environment) -> AnyPublisher<Action,Never>?

let appReducer:Reducer<AppState,AppAction,AppEnvironment> = Reducer{ state,action,environment in
    switch action{
        case .qureyWords(let qurey):
            return environment.getWords(qurey: qurey)
        case .setWords(let words):
            state.words = words
        case .itemAction(let itemAction):
            let effect = itemReducer(&state.itemState, itemAction,environment)
            return effect
                .map(AppAction.itemAction)
                .eraseToAnyPublisher()
        case .memoAction(let memoAction):
            let effect = memoReducer(&state.memoState,memoAction,environment)
            return effect
                .map(AppAction.memoAction)
                .eraseToAnyPublisher()
    }
    return Empty(completeImmediately: true).eraseToAnyPublisher()
}


let itemReducer:Reducer<ItemState,ItemAction,AppEnvironment> = Reducer{ state,action,environment in
    switch action{
        case .setName(let name):
            state.itemName = name
    }
    return Empty(completeImmediately: true).eraseToAnyPublisher()
}

let memoReducer:Reducer<MemoState,MemoAction,AppEnvironment> = Reducer{ state,action,environment in
    switch action{
        case .setMemo(let name):
            state.memoName = name
    }
    return Empty(completeImmediately: true).eraseToAnyPublisher()
}

class Store<State,Action,Environment>:ObservableObject{
    init(intialState:State, enivronment: Environment, reducer: Reducer<State, Action, Environment>,subscriptionQueue:DispatchQueue = .init(label: "com.fatbobman.reduxtest")) {
        self.state = intialState
        self.environment = enivronment
        self.reducer = reducer
        self.queue = subscriptionQueue
    }

    @Published private(set) var state:State
    private let environment:Environment
    private let reducer:Reducer<State,Action,Environment>
    private var cancllables:[UUID:AnyCancellable] = [:]
    private let queue: DispatchQueue

    func send(action:Action) {
        let effect = reducer(&state,action,environment)
        var didComplete = false
        let uuid = UUID()

        let cancellable = effect
            .subscribe(on: queue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion:{ [weak self] _ in
                    didComplete = true
                    self?.cancllables[uuid] = nil
                },
                receiveValue: { [weak self] in
                self?.send(action: $0)
            })

        if !didComplete {
            cancllables[uuid] = cancellable
        }
    }

    func derived<DerivedState:Equatable,ExractedAction>(
        derivedState:@escaping (State) -> DerivedState,
        embedAction:@escaping (ExractedAction) -> Action
    ) -> Store<DerivedState,ExractedAction,Environment>{
        let store = Store<DerivedState,ExractedAction,Environment>(
            intialState: derivedState(state),
            enivronment: environment,
            reducer: Reducer{ _,action,_ in
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


