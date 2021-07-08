//
//  ContentView.swift
//  ReduxTest
//
//  Created by Yang Xu on 2021/7/7.
//

import SwiftUI

struct ContentView: View {
    var body: some View{
        return  TabView{
            ItemRoot()
                .tabItem { Text("item") }
            MemoRoot()
                .tabItem { Text("memo") }
            RootStateRoot()
                .tabItem{ Text("root")}
        }
    }
}

struct RootStateRoot:View{
    @ObservedObject var store = rootStore
    @State var memoName = ""
    @State var itemName = ""
    var body:some View{
        print("main state update")
        return RootStateView(memo: store.state.memoState.memoName,
                             item: store.state.itemState.itemName,
                             memoName: $memoName,
                             itemName: $itemName,
                             memoOnCommit: {store.send(.memoAction(action: .setMemo(name: memoName)))},
                             itemOnCommit: {store.send(.itemAction(action: .setName(name: itemName)))})
    }
}

struct RootStateView:View{
    let memo:String
    let item:String
    @Binding var memoName:String
    @Binding var itemName:String
    let memoOnCommit:() -> Void
    let itemOnCommit:() -> Void
    var body: some View{
        Form{
            Text("memo name:").foregroundColor(.secondary) + Text(memo)
            Text("item name:").foregroundColor(.secondary) + Text(item)
            TextField("input memo name:",text:$memoName,onCommit:memoOnCommit)
            TextField("input item name:",text:$itemName,onCommit:itemOnCommit)
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

struct ItemRoot:View{
    @ObservedObject var store = itemStore
    @State private var itemName = ""
    var body: some View{
        print("item state update")
        return ItemView(itemName: $itemName, item: store.state.itemName,onCommit: {store.send(.setName(name: itemName))})
    }
}

struct ItemView:View{
    @Binding var itemName:String
    let item:String
    var onCommit: () -> Void
    var body: some View{
        Form{
            Text("item name:").foregroundColor(.secondary) + Text(item)
            TextField("input item name:",text:$itemName,onCommit:onCommit)
        }
    }
}

struct MemoRoot:View{
    @ObservedObject var store = memoStore
    @State private var memoName = ""
    var body: some View{
        print("memo state update")
        return
            VStack{
                MemoView(memoName: store.state.memoName, name: $memoName, onCommit: {store.send(.setMemo(name: memoName))})
            }
    }
}

struct MemoView:View{
    let memoName:String
    @Binding var name:String
    var onCommit:() -> Void
    var body: some View{
        Form{
            Text("memo name:").foregroundColor(.secondary) + Text(memoName)
            TextField("input memo name:",text:$name,onCommit:onCommit)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}


