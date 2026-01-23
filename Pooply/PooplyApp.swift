//
//  PooplyApp.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 4/4/25.
//

import SwiftUI


@main
struct PooplyApp: App {
    @StateObject private var userViewModel = UserViewModel(
        user: User(name: "Brandon", age: 27, weight: 170, sex: "male")
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
        }
    }
}
