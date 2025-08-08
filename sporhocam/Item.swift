//
//  Item.swift
//  sporhocam
//
//  Created by Burak Macbook Mini on 8.08.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
