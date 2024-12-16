//
//  ScoreBoardVC.swift
//  matchmania
//
//  Created by Clement Gan on 16/12/2024.
//

import UIKit

class ScoreboardVC: UIViewController, UITableViewDataSource {
    
//    var scores: [(score: Int, time: String)] = [] // Store score and time tuples
    var scores: [ScoreRecord] = [] // Store score record objects
    
    let tableView = UITableView()
    
//    let clearHistoryButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Score History"
        
//        clearHistoryButton.frame = CGRect(x: 20, y: 20, width: 150, height: 40)
//            view.addSubview(clearHistoryButton)
//        clearHistoryButton.setTitle("Clear History", for: .normal)
//        clearHistoryButton.addTarget(self, action: #selector(clearScoreHistory), for: .touchUpInside)

        
        // Set up the tableView
        tableView.frame = view.bounds
//        tableView.frame = CGRect(x: 20, y: 40, width: view.bounds.width, height: view.bounds.height - 40)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScoreCell")
        tableView.register(ScoreCellTVC.self, forCellReuseIdentifier: "ScoreCell")
        view.addSubview(tableView)
        
        // Load saved scores
        loadScores()
    }
    
//    @objc func clearScoreHistory() {
//        UserDefaults.standard.removeObject(forKey: "scoreHistory")
//        scores.removeAll()
//        tableView.reloadData()
//    }
    
    // Table view data source methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath)
//        let scoreRecord = scores[indexPath.row]
//        
//        cell.textLabel?.text = "Score: \(scoreRecord.score) - \(scoreRecord.time)"
//        
//        return cell
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath) as? ScoreCellTVC {
            // Get the score record for this row
            let scoreRecord = scores[indexPath.row]
           
            // Set the text for the game mode, score, and time labels
            cell.gameModeLabel.text = scoreRecord.gameMode
            cell.scoreLabel.text = "Score: \(scoreRecord.score)"
            cell.timeLabel.text = scoreRecord.time
            
            cell.gameModeLabel.textColor = scoreRecord.gameMode == "Hard" ? .systemRed : scoreRecord.gameMode == "Medium" ? .systemOrange : .systemGreen
           
            return cell
        }
        
        return UITableViewCell()
    }
    
    // Load scores from UserDefaults (or another storage method)
    func loadScores() {
        // Retrieve the saved scores
        if let savedScores = UserDefaults.standard.array(forKey: "scoreHistory") as? [[String: Any]] {
            scores = savedScores.compactMap { dict in
                if let gameMode = dict["gameMode"] as? String,
                   let score = dict["score"] as? Int,
                   let time = dict["time"] as? String {
                    return ScoreRecord(gameMode: gameMode, score: score, time: time)
                }
                return nil
            }
        }
        
        // Sort the scores in descending order by score
        scores.sort { $0.score > $1.score }
        
        // Reload the table view to display the updated scores
        tableView.reloadData()
    }
    
    // Save a new score (when the game ends)
        func saveScore(gameMode: String, score: Int, time: String) {
            let newScore = ScoreRecord(gameMode: gameMode, score: score, time: time)
            
            // Save the new score to the UserDefaults (or another persistent storage)
            var currentScores = UserDefaults.standard.array(forKey: "scoreHistory") as? [[String: Any]] ?? []
            currentScores.append([
                "gameMode": gameMode,
                "score": score,
                "time": time
            ])
            UserDefaults.standard.set(currentScores, forKey: "scoreHistory")
            
            // Reload the scores
            loadScores()
        }
    
}
