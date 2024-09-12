//
//  ViewController.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 09/09/24.
//

import UIKit

final class HomeViewController: UIViewController {
    
    private let startButton: UIButton = {
        let button = UIButton()
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.title = String(localized: "Start Detecting")
        buttonConfiguration.image = UIImage(systemName: "hand.thumbsup")
        buttonConfiguration.imagePadding = 8
        button.configuration = buttonConfiguration
        return button
    }()
    
    private let inferenceLabel: UILabel = {
        let inferenceLabel = UILabel()
        inferenceLabel.text = String(localized: "Press button to detect sign")
        inferenceLabel.textAlignment = .center
        return inferenceLabel
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [startButton, inferenceLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    
    private let cameraView = SLRGTKCameraView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
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
        
        startButton.addTarget(self, action: #selector(didTapStartButton(_:)), for: .touchUpInside)
    }
    
    @objc private func didTapStartButton(_ sender: UIButton) {
        cameraView.setupEngine()
    }

}

extension HomeViewController: SLRGTKCameraViewDelegate {
    
    func cameraViewDidSetupEngine() {
        cameraView.fadeIn() {
            self.cameraView.start()
        }
        stackView.fadeOut()
    }
    
    func cameraViewDidBeginInferring() {
        cameraView.stop()
        cameraView.fadeOut()
        stackView.fadeIn()
        startButton.isEnabled = false
        inferenceLabel.text = String(localized: "Inferring")
    }
    
    func cameraViewDidInferSign(_ signInferenceResult: SignInferenceResult) {
        inferenceLabel.text = signInferenceResult.inferences.first?.label
        var buttonConfiguration = startButton.configuration
        buttonConfiguration?.title = String(localized: "Detect Again")
        startButton.configuration = buttonConfiguration
        startButton.isEnabled = true
    }
    
    func cameraViewDidThrowError(_ error: any Error) {
        print(error.localizedDescription)
    }
}

