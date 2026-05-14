//
//  ContentView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = DiaryStore()

    var body: some View {
        HomeView()
            .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
