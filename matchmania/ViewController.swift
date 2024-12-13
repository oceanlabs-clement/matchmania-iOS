//
//  ViewController.swift
//  matchmania
//
//  Created by Clement Gan on 12/12/2024.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    // Unique animal emojis for the game
    var cardValues: [String] = [
        "🐶", "🐱", "🐰", "🐻", "🦁", "🐼", "🐨", "🐸", "🐵", "🐯", "🦄", "🐷", "🦊", "🐯", "🐶", "🐱", "🐸", "🐼", "🦁",
        "🦊", "🐨", "🐵", "🐰", "🦄", "🐷", "🐻", "🐾", "🦋", "🐾", "🐅", "🦄", "🦁", "🦊", "🐱", "🐶", "🦋", "🦸‍♂️"
    ]
    
    var cards = [String]()
    var cardButtons: [UIButton] = []
    
    var firstCardIndex: Int?
    var secondCardIndex: Int?
    var matchedPairs: Set<Int> = []
    
    var scoreLabel = UILabel()
    var score = 0
    
    var gameTimerLabel = UILabel()
    var timer: Timer?
    var remainingTime = 60
    
    var currentMode: String = "Easy" // Default mode is Easy (4x4 grid)
    
    var gridRows: Int = 4
    var gridCols: Int = 4
    
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var tabBarBgView: UIView!
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var floatingBgView: UIView!
    @IBOutlet weak var triggerTabBarButton: UIButton!
    
    
    var urlString = ""
    var homepageUrlString = ""
    
    let safeAreaHeight: CGFloat = 20
    let tabBarHeight: CGFloat = 50
    let panGesture = UIPanGestureRecognizer()
    
    var isCollapse: Bool = false
    var isHideTabBar: Bool = false
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
//        setupModeSelection()
        
        
        floatingBgView.isHidden = true
        floatingBgView.layer.cornerRadius = 10
        
        panGesture.addTarget(self, action: #selector(draggedView(sender:)))
        panGesture.cancelsTouchesInView = true
        
        callApiToCheckStatus()
    }
    
    func setupModeSelection() {
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        
        let bgImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        bgImageView.image = UIImage(named: "image_bg_2")
        bgImageView.contentMode = .scaleAspectFill
        view.addSubview(bgImageView)
        
        // Create UI elements
        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        
        let easyButton = UIButton(type: .system)
        easyButton.setTitle("Easy (4x4)", for: .normal)
        easyButton.addTarget(self, action: #selector(startEasyGame), for: .touchUpInside)
        easyButton.frame = CGRect(x: 100, y: 200, width: 200, height: 60)
        easyButton.setTitleColor(.white, for: .normal)
        easyButton.backgroundColor = .systemGreen
        easyButton.layer.cornerRadius = 10
        easyButton.layer.borderWidth = 2
        easyButton.layer.borderColor = UIColor.white.cgColor
        easyButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        easyButton.addShadow(opacity: 0.25, offsetSize: CGSize(width: 2, height: 5))
        
        let hardButton = UIButton(type: .system)
        hardButton.setTitle("Hard (6x6)", for: .normal)
        hardButton.addTarget(self, action: #selector(startHardGame), for: .touchUpInside)
        hardButton.frame = CGRect(x: 100, y: 300, width: 200, height: 60)
        hardButton.setTitleColor(.white, for: .normal)
        hardButton.backgroundColor = .systemRed
        hardButton.layer.cornerRadius = 10
        hardButton.layer.borderWidth = 2
        hardButton.layer.borderColor = UIColor.white.cgColor
        hardButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        hardButton.addShadow(opacity: 0.25, offsetSize: CGSize(width: 2, height: 5))
        
        // Create StackView for buttons
        let buttonStackView = UIStackView(arrangedSubviews: [easyButton, hardButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 20
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)
        
        // Set Auto Layout constraints
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 150),
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50)
        ])
    }
    
    @objc func startEasyGame() {
        currentMode = "Easy"
        gridRows = 4
        gridCols = 4
        setupGame()
        setupUI()
        startTimer()
    }
    
    @objc func startHardGame() {
        currentMode = "Hard"
        gridRows = 6
        gridCols = 6
        setupGame()
        setupUI()
        startTimer()
    }
    
    func setupGame() {
        // Duplicate and shuffle card values based on grid size
        let totalCards = gridRows * gridCols
        let neededPairs = totalCards / 2
        let selectedValues = Array(cardValues.prefix(neededPairs))
        let duplicatedValues = selectedValues + selectedValues // Duplicate for pairs
        cards = duplicatedValues.shuffled()
        
        // Reset game state
        matchedPairs.removeAll()
        score = 0
        remainingTime = 60
        gameTimerLabel.text = "Time: \(remainingTime)s"
        scoreLabel.text = "Score: \(score)"
    }
    
    func setupUI() {
        // Clean up any existing UI elements (if any)
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        
        let bgImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        bgImageView.image = UIImage(named: "image_bg_2")
        bgImageView.contentMode = .scaleAspectFill
        view.addSubview(bgImageView)
        
        // Score label
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.text = "Score: \(score)"
        scoreLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        view.addSubview(scoreLabel)
        
        // Timer label
        gameTimerLabel.translatesAutoresizingMaskIntoConstraints = false
        gameTimerLabel.text = "Time: \(remainingTime)s"
        gameTimerLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        view.addSubview(gameTimerLabel)
        
        // Set up grid
        let gridLayout = UIStackView()
        gridLayout.axis = .vertical
        gridLayout.spacing = 10
        gridLayout.translatesAutoresizingMaskIntoConstraints = false
        
        for row in 0..<gridRows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            
            for col in 0..<gridCols {
                let index = row * gridCols + col
                let button = UIButton(type: .system)
                button.setTitle("❓", for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 32)
                button.tag = index
                button.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
                cardButtons.append(button)
            }
            
            gridLayout.addArrangedSubview(rowStack)
        }
        
        view.addSubview(gridLayout)
        
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            gameTimerLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            gameTimerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            gridLayout.topAnchor.constraint(equalTo: gameTimerLabel.bottomAnchor, constant: 20),
            gridLayout.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridLayout.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    // MARK: - Card Tap Event
    
    @objc func cardTapped(_ sender: UIButton) {
        let index = sender.tag
        
        // Ignore if card is already matched or revealed
        guard !matchedPairs.contains(index) else { return }
        
        // If it's the first card, reveal it and wait for the second
        if firstCardIndex == nil {
            firstCardIndex = index
            revealCard(at: index)
        } else if secondCardIndex == nil {
            secondCardIndex = index
            revealCard(at: index)
            
            // Check if it's a match after the second card
            checkForMatch()
        }
    }
    
    func revealCard(at index: Int) {
        UIView.transition(with: cardButtons[index], duration: 0.5, options: .transitionFlipFromLeft, animations: {
            self.cardButtons[index].setTitle(self.cards[index], for: .normal)
        }, completion: nil)
    }
    
    func hideCard(at index: Int) {
        UIView.transition(with: cardButtons[index], duration: 0.5, options: .transitionFlipFromRight, animations: {
            self.cardButtons[index].setTitle("❓", for: .normal)
        }, completion: nil)
    }
    
    func checkForMatch() {
        guard let firstIndex = firstCardIndex, let secondIndex = secondCardIndex else { return }
        
        if cards[firstIndex] == cards[secondIndex] {
            // Match found
            matchedPairs.insert(firstIndex)
            matchedPairs.insert(secondIndex)
            score += 1
            scoreLabel.text = "Score: \(score)"
        } else {
            // No match, flip cards back after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hideCard(at: firstIndex)
                self.hideCard(at: secondIndex)
            }
        }
        
        // Reset selected card indexes
        firstCardIndex = nil
        secondCardIndex = nil
        
        // Check if the game is over
        if matchedPairs.count == cards.count {
            timer?.invalidate()
            gameOver()
        }
    }
    
    // MARK: - Setup Timer
    
    func startTimer() {
        // Start the countdown timer for the game
        timer?.invalidate() // Invalidate any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        remainingTime -= 1
        gameTimerLabel.text = "Time: \(remainingTime)s"
        
        if remainingTime <= 0 {
            timer?.invalidate()
            gameOver()
        }
    }
    
    func gameOver() {
        // Show game over message in a pop-up alert
        let alertController = UIAlertController(title: "Game Over", message: "Your final score is \(score).", preferredStyle: .alert)
        
        let resetAction = UIAlertAction(title: "Play Again", style: .default) { _ in
            self.resetGame()
        }
        let cancelAction = UIAlertAction(title: "Exit", style: .cancel) { _ in
//            DispatchQueue.main.async {
                self.setupModeSelection()
//            }
        }
        
        alertController.addAction(resetAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func resetGame() {
        // Reset the game state and UI
        matchedPairs.removeAll()
        score = 0
        scoreLabel.text = "Score: \(score)"
        remainingTime = 60
        gameTimerLabel.text = "Time: \(remainingTime)s"
        
        // Reinitialize cards for a fresh start
        setupGame()
        setupUI()
        startTimer()
    }
}

extension ViewController {
    
    // MARK: - Call Api
    
    func callApiToCheckStatus() {
        let semaphore = DispatchSemaphore (value: 0)
        
        var request = URLRequest(url: URL(string: "https://6703907dab8a8f892730a6d2.mockapi.io/api/v1/hockeybattlee")!, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    guard let self = self else { return }
//                    self.loadingView.stopAnimating()
                }
                print(String(describing: error))
                semaphore.signal()
                return
            }
//            print("\n[ViewController] thesnake data: ")
//            print(String(data: data, encoding: .utf8)!)
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [[String:Any]]
//                print("\nCheck json data: ", json)
                
                if let isOpen = json?[0]["is_on"] as? Bool {
                    if isOpen == true {
                        self.urlString = json?[0]["url"] as? String ?? ""
                        if let url = URL(string: self.urlString) {
                            let request = URLRequest(url: url)
                            
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                triggerTabBarButton.addGestureRecognizer(panGesture)
                                triggerTabBarButton.touchesCancelled([], with: nil)
                                
                                self.view.backgroundColor = .black
//                                self.gameBgView.isHidden = true
                                self.floatingBgView.isHidden = false
                                self.webView.isHidden = false
                                self.webView.load(request)
                                
                                self.webView.uiDelegate = self
                                self.webView.navigationDelegate = self
                                
                                stackView.isHidden = false
                                tabBarBgView.isHidden = false
                                tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height-tabBarHeight-safeAreaHeight, width: self.view.bounds.width, height: tabBarHeight)
                            }
                        }
                        else {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                setupModeSelection()
                                
                                self.view.backgroundColor = .white
//                                self.gameBgView.isHidden = false
                                self.floatingBgView.isHidden = true
                                self.webView.isHidden = true
//                                self.startNewGame()
                                
                                stackView.isHidden = true
                                tabBarBgView.isHidden = true
                                tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 0)
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            setupModeSelection()
                            
                            self.view.backgroundColor = .white
//                            self.gameBgView.isHidden = false
                            self.floatingBgView.isHidden = true
                            self.webView.isHidden = true
//                            self.startNewGame()
                            
                            stackView.isHidden = true
                            tabBarBgView.isHidden = true
                            tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 0)
                        }
                    }
                }
                else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        setupModeSelection()
                        
                        self.view.backgroundColor = .white
//                        self.gameBgView.isHidden = false
                        self.floatingBgView.isHidden = true
                        self.webView.isHidden = true
//                        self.startNewGame()
                        
                        stackView.isHidden = true
                        tabBarBgView.isHidden = true
                        tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 0)
                    }
                    
                }
                
//                let jsonData = try JSONDecoder().decode([GetDataResponse].self, from: data)
//                print("\nJson data:")
//                print(jsonData)
                
            } catch let jsonError {
//                print("[API checkStatus] Failed to decode:", jsonError)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    setupModeSelection()
                    
                    self.view.backgroundColor = .white
//                    self.gameBgView.isHidden = false
                    self.floatingBgView.isHidden = true
                    self.webView.isHidden = true
//                    self.startNewGame()
                    
                    stackView.isHidden = true
                    tabBarBgView.isHidden = true
                    tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 0)
                }
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    @IBAction func button2OnTapped(_ sender: Any) {
        
        guard let button = sender as? UIButton else { return }
        
        if button == homeButton {
            if let url = URL(string: self.homepageUrlString) {
                let request = URLRequest(url: url)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.webView.load(request)
                }
            }
        }
        else if button == leftButton {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.webView.goBack()
            }
        }
        else if button == rightButton {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.webView.goForward()
            }
        }
        else if button == refreshButton {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.webView.reload()
            }
        }
        else if button == triggerTabBarButton {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                isHideTabBar = !isHideTabBar
                tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height-tabBarHeight, width: self.view.bounds.width, height: isHideTabBar == true ? 0 : tabBarHeight)
                tabBarBgView.isHidden = isHideTabBar == true ? true : false
                
                if isHideTabBar == true {
                    webView.frame = CGRect(x: 0, y: tabBarHeight, width: self.view.bounds.width, height: self.view.bounds.height-tabBarHeight)
                    tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height+safeAreaHeight, width: self.view.bounds.width, height: 0)
                }
                else {
                    webView.frame = CGRect(x: 0, y: tabBarHeight, width: self.view.bounds.width, height: self.view.bounds.height-tabBarHeight-safeAreaHeight-tabBarHeight)
                    tabBarBgView.frame = CGRect(x: 0, y: self.view.bounds.height-tabBarHeight-safeAreaHeight, width: self.view.bounds.width, height: tabBarHeight)
                }
            }
        }
        // end else if
        
    }
    
    // MARK: - Orientation Change
    
    @objc func orientationChange() {
        draggedView(sender: panGesture)
    }
    
    // MARK: - Floating View Pan Gesture
    
    @objc func draggedView(sender: UIPanGestureRecognizer) {
        self.view.bringSubviewToFront(floatingBgView)
        let translation = sender.translation(in: self.view)
        let xPostion = floatingBgView.center.x + translation.x
        let yPostion = floatingBgView.center.y + translation.y - floatingBgView.frame.height
        
        if UIDevice.current.orientation == .portrait {
            if (xPostion >= 25 && xPostion <= self.view.frame.size.width - 25) && (yPostion >= 30 && yPostion <= self.view.frame.size.height-150) {
                floatingBgView.center = CGPoint(x: floatingBgView.center.x + translation.x, y: floatingBgView.center.y + translation.y)
                sender.setTranslation(.zero, in: self.view)
                
            }
        }
        else {
            if (xPostion >= (25+48) && xPostion <= self.view.frame.size.width - (25+48) ) && (yPostion >= -20 && yPostion <= self.view.frame.size.height-100) {
                floatingBgView.center = CGPoint(x: floatingBgView.center.x + translation.x, y: floatingBgView.center.y + translation.y)
                sender.setTranslation(.zero, in: self.view)
                
            }
        }
        
    }
    
}

// MARK: - Web View UI Delegate

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (!(navigationAction.targetFrame?.isMainFrame ?? false)) {
            self.webView.load(navigationAction.request)
            
//            homepageUrlString = "\(navigationAction.request.url)"
//            print("\nCreate webview with: ")
//            print("homepageUrlString: ", homepageUrlString)
        }
        
        return nil
    }
}

// MARK: - Web View Navigation Delegate

extension ViewController: WKNavigationDelegate {
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
//        homepageUrlString = "\(navigationAction.request.url)"
//        print("\nDecidePolicyFor: ")
//        print("homepageUrlString: ", homepageUrlString)
//        return .allow
//    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let newUrl = webView.url?.absoluteString {
            if homepageUrlString.count == 0 {
                homepageUrlString = newUrl
//                print("\nDidReceiveServerRedirect: ")
//                print("homepageUrlString: ", homepageUrlString)
            }
        }
    }
}

extension UIView {
    func addShadow(opacity: Float, offsetSize: CGSize) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = opacity //0.25
        self.layer.shadowOffset = offsetSize //CGSize(width: 0, height: -2)
        self.layer.shadowRadius = 4
    }
}


