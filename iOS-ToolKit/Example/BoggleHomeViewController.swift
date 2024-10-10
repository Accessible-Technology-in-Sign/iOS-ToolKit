//
//  BoggleHomeViewController.swift
//  iOS-ToolKit
//
//  Created by Unnathi Utpal Kumar on 10/02/24.
//
import UIKit

final class BoggleHomeViewController: UIViewController {
    private let gridSize: Int
    private var boardButtons: [[UIButton]] = []
    private var currentWord: String = ""
    private let game: BoggleGame
    private var inferenceLabel: UILabel!
    private var submitButton: UIButton = UIButton()
    private var signButton: UIButton = UIButton()
    private let cameraView = SLRGTKCameraView()
    private var containerView = UIView()
    
    private var currSubmission: [(Int, Int)] = []
    
    init(words: Set<String>, gridSize: Int) {
        self.game = BoggleGame(gridSize: gridSize, words: words)
        self.gridSize = gridSize
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupCameraView()
        setupContainerView()
        
        setupBoard()
        setupWordLabel()
        setupSubmitButton()
        setupSignButton()
    }
    
    private func setupCameraView() {
            cameraView.isHidden = true
            view.addSubview(cameraView)
            cameraView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                cameraView.topAnchor.constraint(equalTo: view.topAnchor),
                cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            cameraView.delegate = self
    }
    
    private func setupContainerView() {
            containerView.backgroundColor = .clear
            view.addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    private func setupBoard() {
        let buttonSize: CGFloat = 60
        let padding: CGFloat = 10
        let boardSize = CGFloat(gridSize) * buttonSize + CGFloat(gridSize - 1) * padding
        
        for row in 0..<gridSize {
            var buttonRow: [UIButton] = []
            for col in 0..<gridSize {
                let button = UIButton()
                button.setTitle(game.board[row][col], for: .normal)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
                button.backgroundColor = .lightGray
                button.setTitleColor(.white, for: .normal)
                button.tag = row * gridSize + col
                button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                
                containerView.addSubview(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                button.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
                button.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
                
                let xPosition = CGFloat(col) * (buttonSize + padding) + 195
                let yPosition = CGFloat(row) * (buttonSize + padding) + 100
                button.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: xPosition + (containerView.bounds.width - boardSize) / 2).isActive = true
                button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: yPosition).isActive = true
                
                buttonRow.append(button)
            }
            boardButtons.append(buttonRow)
        }
    }
    
    private func setupWordLabel() {
        inferenceLabel = UILabel()
        inferenceLabel.textAlignment = .center
        inferenceLabel.font = UIFont.boldSystemFont(ofSize: 32)
        inferenceLabel.text = "Word: "
        inferenceLabel.textColor = .black
        
        containerView.addSubview(inferenceLabel)
        inferenceLabel.translatesAutoresizingMaskIntoConstraints = false
        inferenceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        inferenceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40).isActive = true
    }
    
    private func setupSubmitButton() {
        submitButton.setTitle("Submit", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        submitButton.backgroundColor = .blue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.addTarget(self, action: #selector(submitWord), for: .touchUpInside)

        containerView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        
        let buttonSize: CGFloat = 60
        let padding: CGFloat = 10
        let boardHeight = CGFloat(gridSize) * buttonSize + CGFloat(gridSize - 1) * padding
        
        submitButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: boardHeight + 150).isActive = true
        submitButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setupSignButton() {
        signButton.setTitle("Sign", for: .normal)
        signButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        signButton.backgroundColor = .blue
        signButton.setTitleColor(.white, for: .normal)
        signButton.addTarget(self, action: #selector(didTouchDownInsideStartButton(_:)), for: .touchDown)
        signButton.addTarget(self, action: #selector(didTouchUpStartButton(_:)), for: .touchUpInside)
        signButton.addTarget(self, action: #selector(didTouchUpStartButton(_:)), for: .touchUpOutside)

        containerView.addSubview(signButton)
        signButton.translatesAutoresizingMaskIntoConstraints = false
        signButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        
        signButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 20).isActive = true
        signButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        signButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setupInferenceLabel() {
        let inferenceLabel = UILabel()
        inferenceLabel.text = String(localized: "Press button to detect sign")
        inferenceLabel.textAlignment = .center
        
        signButton.topAnchor.constraint(equalTo: signButton.bottomAnchor, constant: 20).isActive = true
        signButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        signButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    @objc private func didTouchDownInsideStartButton(_ sender: UIButton) {
        cameraView.setupEngine()
        cameraView.fadeIn() {
            self.cameraView.start()
        }
        containerView.fadeOut(modifiesHiddenBehaviour: false)
    }
    
    @objc private func didTouchUpStartButton(_ sender: UIButton) {
        cameraView.detect()
        cameraView.fadeOut()
        containerView.fadeIn(modifiesHiddenBehaviour: false)
        signButton.isEnabled = false
        inferenceLabel.text = String(localized: "Processing")
    }
    
    
    
    @objc private func letterTapped(_ sender: UIButton) {
        let row = sender.tag / gridSize
        let col = sender.tag % gridSize
        let letter = game.board[row][col]
        currentWord += letter
        inferenceLabel.text = "Word: \(currentWord)"
        
        currSubmission.append((row, col))
    }
    
    @objc private func submitWord() {
        if game.words.contains(currentWord) {
            highlightFoundWord()
        } else {
            let alert = UIAlertController(title: "Invalid Word", message: "The word '\(currentWord)' is not valid.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        currentWord = ""
        inferenceLabel.text = "Word: "
        currSubmission.removeAll()
    }
    
    private func highlightFoundWord() {
        for (row, col) in currSubmission {
            boardButtons[row][col].backgroundColor = .green
        }
    }
}

class BoggleGame {
    let gridSize: Int
    var board: [[String]]
    private var visited: [[Bool]]
    private let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    var words: Set<String>
    
    init(gridSize: Int, words: Set<String>) {
        self.gridSize = gridSize
        self.board = Array(repeating: Array(repeating: "", count: gridSize), count: gridSize)
        self.visited = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        self.words = words
        generateBoard()
    }
    
    private func generateBoard() {
        for word in words {
            placeWordOnBoard(word)
        }
        
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                if board[i][j] == "" {
                    board[i][j] = String(letters.randomElement()!)
                }
            }
        }
    }
    
    private func placeWordOnBoard(_ word: String) {
        let wordLength = word.count
        let wordArray = Array(word)
        
        for _ in 0..<100 { // what's a good number of retries?
            let startRow = Int.random(in: 0..<gridSize)
            let startCol = Int.random(in: 0..<gridSize)
            let direction = directions.randomElement()!
            
            if canPlaceWord(wordArray, row: startRow, col: startCol, direction: direction) {
                for i in 0..<wordLength {
                    let newRow = startRow + i * direction.0
                    let newCol = startCol + i * direction.1
                    board[newRow][newCol] = String(wordArray[i])
                }
                return
            }
        }
        print("Could not place word: \(word)")
    }
    
    private func canPlaceWord(_ wordArray: [Character], row: Int, col: Int, direction: (Int, Int)) -> Bool {
        let wordLength = wordArray.count
        
        for i in 0..<wordLength {
            let newRow = row + i * direction.0
            let newCol = col + i * direction.1
            
            if newRow < 0 || newCol < 0 || newRow >= gridSize || newCol >= gridSize {
                return false
            }
            
            // if we already put a word there
            if board[newRow][newCol] != "" && board[newRow][newCol] != String(wordArray[i]) {
                return false
            }
        }
        return true
    }
}

extension BoggleHomeViewController: SLRGTKCameraViewDelegate {
    
    func cameraViewDidSetupEngine() {
        print("Did setup engine")
    }
    
    func cameraViewDidBeginInferring() {
        inferenceLabel.text = String(localized: "Inferring")
    }
    
    func cameraViewDidInferSign(_ signInferenceResult: SignInferenceResult) {
        inferenceLabel.text = signInferenceResult.inferences.first?.label
        resetDetectButton()
    }
    
    func cameraViewDidThrowError(_ error: any Error) {
        DispatchQueue.main.async {
            self.inferenceLabel.text = "Error!"
            self.resetDetectButton()
        }
        
        print(error.localizedDescription)
    }
    
    private func resetDetectButton() {
        var buttonConfiguration = signButton.configuration
        buttonConfiguration?.title = String(localized: "Detect Again")
        signButton.configuration = buttonConfiguration
        signButton.isEnabled = true
    }
}
