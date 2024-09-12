//
//  ViewController.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 09/09/24.
//

import UIKit

final class HomeViewController: UIViewController {
    
    private let cameraView = SLRGTKCameraView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraView.start()
    }

}

extension HomeViewController: SLRGTKCameraViewDelegate {
    func cameraViewDidInferSign(_ signInferenceResult: SignInferenceResult) {
        print(signInferenceResult.inferences)
    }
    
    func cameraViewDidThrowError(_ error: any Error) {
        print(error.localizedDescription)
    }
    
    
}

