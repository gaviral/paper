//
//  ViewController.swift
//  paper
//
//  Created by Aviral Garg on 2023-12-30.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {
    // This outlet connects the SKView in the storyboard to the code
    @IBOutlet private var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // This method handles scroll wheel events
    override func scrollWheel(with event: NSEvent) {
        (skView.scene as? GameScene)?.handleScrollEvent(event)
    }
}

// MARK: - Setup Methods
private extension ViewController {
    // This method sets up the view
    func setupView() {
        guard let view = skView, let scene = SKScene(fileNamed: "GameScene") else {
            // Handle the error here
            return
        }
        scene.scaleMode = .aspectFill
        view.presentScene(scene)
        setupDebugging(for: view)
    }
    
    // This method sets up debugging for the view
    func setupDebugging(for view: SKView) {
        view.ignoresSiblingOrder = true
        view.showsFPS = true
        view.showsNodeCount = true
        view.showsFields = true
        view.showsPhysics = true
        view.showsDrawCount = true
        view.showsQuadCount = true
    }
}
