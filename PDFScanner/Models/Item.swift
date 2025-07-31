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
    var pdfData: Data?
    
    init(timestamp: Date, pdfData: Data? = nil) {
        self.timestamp = timestamp
        self.pdfData = pdfData
    }
}
