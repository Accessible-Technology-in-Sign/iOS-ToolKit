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
    private var wordLabel: UILabel!
    private var submitButton: UIButton = UIButton()
    
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
        setupBoard()
        setupWordLabel()
        setupSubmitButton()
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
                
                view.addSubview(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                button.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
                button.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
                
                let xPosition = CGFloat(col) * (buttonSize + padding)
                let yPosition = CGFloat(row) * (buttonSize + padding) + 100
                button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: xPosition + (view.bounds.width - boardSize) / 2).isActive = true
                button.topAnchor.constraint(equalTo: view.topAnchor, constant: yPosition).isActive = true
                
                buttonRow.append(button)
            }
            boardButtons.append(buttonRow)
        }
    }
    
    private func setupWordLabel() {
        wordLabel = UILabel()
        wordLabel.textAlignment = .center
        wordLabel.font = UIFont.boldSystemFont(ofSize: 32)
        wordLabel.text = "Word: "
        wordLabel.textColor = .black
        
        view.addSubview(wordLabel)
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        wordLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
    }
    
    private func setupSubmitButton() {
        submitButton.setTitle("Submit", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        submitButton.backgroundColor = .blue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.addTarget(self, action: #selector(submitWord), for: .touchUpInside)

        view.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let buttonSize: CGFloat = 60
        let padding: CGFloat = 10
        let boardHeight = CGFloat(gridSize) * buttonSize + CGFloat(gridSize - 1) * padding
        
        submitButton.topAnchor.constraint(equalTo: view.topAnchor, constant: boardHeight + 150).isActive = true
        submitButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    @objc private func letterTapped(_ sender: UIButton) {
        let row = sender.tag / gridSize
        let col = sender.tag % gridSize
        let letter = game.board[row][col]
        currentWord += letter
        wordLabel.text = "Word: \(currentWord)"
        
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
        wordLabel.text = "Word: "
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
