//
//  Item.swift
//  PDFScanner
//
//  Created by Marcin Kondrat on 7/31/25.
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
