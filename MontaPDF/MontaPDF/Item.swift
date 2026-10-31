//
//  Item.swift
//  MontaPDF
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date = Date()
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
