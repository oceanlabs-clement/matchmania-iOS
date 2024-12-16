//
//  ScoreRecord.swift
//  matchmania
//
//  Created by Clement Gan on 16/12/2024.
//

import Foundation

struct ScoreRecord {
    var gameMode: String
    var score: Int
    var time: String // The time the score was achieved in a readable format
    
//    init(score: Int) {
//        self.score = score
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Format the time to display in a readable format
//        self.time = formatter.string(from: Date()) // Get the current date and time
//    }
}
