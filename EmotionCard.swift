//
//  EmotionCard.swift
//  Lumis
//
//  Created by Shuiii on 3/6/25.
//

import Foundation
import SwiftData

@Model
class EmotionCard: ObservableObject, Identifiable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var rawInput: String
    var responseText: String
    var quote: String
    
    @Relationship(deleteRule: .nullify) var relatedEnergyDiagnosis: EnergyDiagnosis?
    @Relationship(deleteRule: .nullify) var userProfile: UserEnergyProfile?

    init(rawInput: String,responseText: String, quote: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.rawInput = rawInput
        self.responseText = responseText
        self.quote = quote
        self.timestamp = timestamp
    }
    
}
