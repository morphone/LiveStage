//
//  Item.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
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
