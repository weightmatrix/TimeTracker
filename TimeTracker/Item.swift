//
//  Item.swift
//  TimeTracker
//
//  Created by 李中正 on 2025/12/4.
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
