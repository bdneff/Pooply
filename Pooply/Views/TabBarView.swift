//
//  TabBarView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 4/4/25.
//

import SwiftUI

struct TabBarView: View {
    @Namespace var animation
    @Binding var selectedTab: String
    @Binding var didPressButton: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(animation: animation, imageString: "house.fill", selectedTab: $selectedTab)
            TabBarButton(animation: animation, imageString: "calendar", selectedTab: $selectedTab)
            Button(action: {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                didPressButton = true
            }) {
                ZStack {
                    Circle().fill(Color(.systemBlue).gradient).frame(width: 64, height: 64)
                    Image("plus").resizable().scaledToFit().frame(width: 80, height: 80)
                }
            }.offset(y: -24)
            TabBarButton(animation: animation, imageString: "chart.line.uptrend.xyaxis", selectedTab: $selectedTab)
            TabBarButton(animation: animation, imageString: "person.fill", selectedTab: $selectedTab)
        }
        .padding(.vertical, -16)
        .background(Color.pooplyDarkBeige)
    }
}

struct TabBarButton: View {
    var animation: Namespace.ID
    var imageString: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                selectedTab = imageString
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: imageString).resizable().aspectRatio(contentMode: .fit).frame(width: 24, height: 24)
                    .foregroundStyle(selectedTab == imageString ? Color(.black) : Color.black)
                    .bold()
                if selectedTab == imageString {
                    Circle()
                        .fill(Color(.systemBlue))
                        .matchedGeometryEffect(id: "TAB", in: animation)
                        .frame(width: 8, height: 8)
                }
            }
        }.frame(maxWidth: .infinity)
    }
}

