//
//  ContentView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import SwiftUI

enum Tab: CaseIterable {
    case home
    case insights

    var icon: String {
        switch self {
            case .home: return "house.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var selectedTab: Tab = .home
    @State private var didPressPoopButton: Bool = false
    @State private var showProfileModal: Bool = false
    @State private var showCameraView: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var showWelcomeView: Bool = true
    
    var body: some View {
        ZStack {
            Color(hex: "#cff1e5").ignoresSafeArea()
            BlurredBackgroundView()

            if showWelcomeView {
                WelcomeView(isPresented: $showWelcomeView)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                VStack {
                    // Switch between views
                    switch selectedTab {
                    case .home:
                        HomeView(showCameraView: $showCameraView, showManualEntry: $showManualEntry)
                    case .insights:
                        InsightsView()
                            .environmentObject(userViewModel)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))

                // Floating tab bar with ultra thin material
                VStack {
                    Spacer()
                    HStack(spacing: 32) {
                        Button(action: { selectedTab = .home }) {
                            Image(systemName: "house.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(selectedTab == .home ? Color(hex: "#19b888") : Color(hex: "#1f1f1f"))
                        }
                        Button(action: { showCameraView = true }) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color(hex: "#1f1f1f"))
                                .bold()
                                .padding(8.0)
                                .background(Color(hex: "#19b888"))
                                .clipShape(Circle())
                        }
                        Button(action: { selectedTab = .insights }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(selectedTab == .insights ? Color(hex: "#19b888") : Color(hex: "#1f1f1f"))
                        }
                    }
                    .padding(8.0)
                    .padding(.horizontal, 12.0)
                    .background(Color(hex: "#e5fff7"))
                    .clipShape(Capsule())
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraView(isPresented: $showCameraView, showManualEntry: $showManualEntry)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(isPresented: $showManualEntry)
        }
        .sheet(isPresented: $showProfileModal) {
            ProfileModal(isPresented: $showProfileModal)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            UserViewModel(
                user: User(
                    name: "Preview User",
                    age: 25,
                    weight: 160,
                    sex: "female"
                ),
                withDummyData: true
            )
        )
}

