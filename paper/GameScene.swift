//
//  GameScene.swift
//  paper
//
//  Created by Aviral Garg on 2023-12-30.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var initialLabel: SKLabelNode?
    private var spinnyNode: SKShapeNode?
    private var lastAreaNumber: Int = 0
    private var lastMousePosition: CGPoint?

    override func didMove(to view: SKView) {
        setupInitialLabel()
        setupSpinnyNode()
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

    // MARK: - Setup Methods
    fileprivate func setupInitialLabel() {
        self.initialLabel = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.initialLabel {
            fadeIn(node: label, over: 2.0)
        }
    }

    fileprivate func setupSpinnyNode() {
        let w = (self.size.width + self.size.height) * 0.05
        spinnyNode = SKShapeNode(rectOf: CGSize(width: w, height: w), cornerRadius: w * 0.3)

        if let spinnyNode = spinnyNode {
            spinnyNode.lineWidth = 2.5
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }

    // MARK: - Animation Methods
    fileprivate func fadeIn(node: SKNode, over duration: TimeInterval) {
        node.alpha = 0.0
        node.run(SKAction.fadeIn(withDuration: duration))
    }

    // MARK: - Touch Handling Methods
    func touchDown(atPoint pos: CGPoint) {
        createSpinnyNode(at: pos, withColor: .green)
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        createSpinnyNode(at: pos, withColor: .blue)
    }
    
    func touchUp(atPoint pos: CGPoint) {
        createSpinnyNode(at: pos, withColor: .red)
    }

    fileprivate func createSpinnyNode(at position: CGPoint, withColor color: SKColor) {
        if let n = self.spinnyNode?.copy() as? SKShapeNode {
            n.position = position
            n.strokeColor = color
            self.addChild(n)
        }
    }

    // MARK: - Event Handling
    override func mouseDown(with event: NSEvent) {
        let mouseDownLocation = event.location(in: self)
        lastMousePosition = event.location(in: self)

        touchDown(atPoint: mouseDownLocation)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let lastMouse = lastMousePosition else {
            return
        }
        let mousePosition = event.location(in: self)
        let movementDelta = CGPoint(x: mousePosition.x - lastMouse.x, y: mousePosition.y - lastMouse.y)

        moveScene(by: movementDelta)
        lastMousePosition = mousePosition

        touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        lastMousePosition = nil

        touchUp(atPoint: event.location(in: self))
    }

    override func keyDown(with event: NSEvent) {
        handleKeyDownEvent(with: event)
    }

    fileprivate func handleKeyDownEvent(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:
            handleSpaceBarKeyPress()
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }

    private func handleSpaceBarKeyPress() {
        createNewAreaOnPaper(at: CGPoint(x: 0, y: 0))
        
        if let label = self.initialLabel {
            label.run(SKAction(named: "Pulse")!, withKey: "fadeInOut")
        }
    }

    // MARK: - Utility Methods
    func createLabel(text: String, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.position = position
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 50
        label.fontColor = .white
        label.zPosition = 1
        return label
    }
    
    fileprivate func createNewAreaOnPaper(at location: CGPoint) {
        addChild(createLabel(text: "\(lastAreaNumber)", position: location))
        lastAreaNumber += 1
    }

    private func moveScene(by delta: CGPoint) {
        for node in children {
            node.position = CGPoint(x: node.position.x + delta.x, y: node.position.y + delta.y)
        }
    }
}
