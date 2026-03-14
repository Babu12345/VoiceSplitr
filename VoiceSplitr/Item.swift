//
//  Item.swift
//  VoiceSplitr
//
//  Created by Babu Wanyeki on 3/14/26.
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
