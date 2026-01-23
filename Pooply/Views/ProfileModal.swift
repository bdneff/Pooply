//
//  ProfileModal.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 10/24/25.
//

import SwiftUI

struct ProfileModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        ZStack {
            Color(hex: "#cff1e5").ignoresSafeArea()
            VStack {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                            .frame(width: 20, height: 20)
                            .padding()
                            .background(Color(hex: "#e5fff7"))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Profile")
                        .font(.custom("Nunito Bold", size: 24))
                        .foregroundColor(Color(hex: "#1f1f1f"))
                    Spacer()
                    // Invisible button for balance
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.clear)
                            .frame(width: 20, height: 20)
                            .padding()
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        // User Info Card
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color(hex: "#19b888").opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(hex: "#19b888"))
                                )

                            VStack(spacing: 4) {
                                Text(userViewModel.user.name)
                                    .font(.custom("Nunito Bold", size: 20))
                                    .foregroundColor(Color(hex: "#1f1f1f"))
                                Text("\(userViewModel.logHistory.count) total logs")
                                    .font(.custom("Nunito Regular", size: 14))
                                    .foregroundColor(Color(hex: "#1f1f1f"))
                            }
                        }
                        .padding()
                        .background(Color(hex: "#e5fff7"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Settings Options
                        VStack(spacing: 12) {
                            ProfileOptionCard(
                                icon: "doc.text",
                                title: "Terms of Service",
                                action: { /* TODO: Add Terms functionality */ }
                            )

                            ProfileOptionCard(
                                icon: "hand.raised.fill",
                                title: "Privacy Policy",
                                action: { /* TODO: Add Privacy functionality */ }
                            )

                            ProfileOptionCard(
                                icon: "creditcard",
                                title: "Manage Subscription",
                                action: { /* TODO: Add Subscription functionality */ }
                            )

                            ProfileOptionCard(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Log Out",
                                isDestructive: true,
                                action: { /* TODO: Add Logout functionality */ }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct ProfileOptionCard: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void

    init(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isDestructive ? .red : Color(hex: "#19b888"))
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.custom("Nunito Medium", size: 16))
                    .foregroundColor(isDestructive ? .red : Color(hex: "#1f1f1f"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1f1f1f"))
            }
            .padding()
            .background(Color(hex: "#e5fff7"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileModal(isPresented: .constant(true))
        .environmentObject(
            UserViewModel(
                user: User(
                    name: "John Doe",
                    age: 25,
                    weight: 160,
                    sex: "male"
                ),
                withDummyData: true
            )
        )
}
