//
//  User.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import Foundation

struct User: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var age: Int
    var weight: Double
    var gender: String
}

