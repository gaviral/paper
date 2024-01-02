//
//  GameScene.swift
//  paper
//
//  Created by Aviral Garg on 2023-12-30.
//

import SpriteKit
import OpenAI


struct Constants {
    static let labelFontSize: CGFloat = 48
    static let labelZPosition: CGFloat = 1
    static let threshold: CGFloat = 0.0
}

class GameScene: SKScene {
    private let paper = SKNode()
    private var halfWidth: CGFloat { size.width / 2 }
    private var halfHeight: CGFloat { size.height / 2 }

    override func didMove(to view: SKView) {
        setupWorldNode()
        addLabelAndBackground()
        setupGestureRecognizers(in: view)

        // Use a task to handle async calls
        Task {
            await openAI()
        }
    }
}

private extension GameScene {

    func openAI() async {

        var apiKey: String {
            ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        }

        var organization: String {
            ProcessInfo.processInfo.environment["OPENAI_ORGANIZATION"]!
        }

        let openAI = OpenAI(apiToken: apiKey)

        // examples of how to use the API

        enum testOpenAI {
            case completions
        }

        do {
            switch testOpenAI.completions {
            case .completions:
                let query = CompletionsQuery(model: .textDavinci_003, prompt: "What is 42?", temperature: 0, maxTokens: 100, topP: 1, frequencyPenalty: 0, presencePenalty: 0, stop: ["\\n"])
                openAI.completions(query: query) { result in
                    //Handle result here
                }
                //or
                let result = try await openAI.completions(query: query)
                print(result)
            }


        } catch let error as APIErrorResponse {
            print(error)
        } catch {
            print(error)
        }
    }


    // This method sets up the world node by adding it as a child node
    func setupWorldNode() {
        addChild(paper)
    }

    // This method adds a label and a background to the world node
    func addLabelAndBackground() {
        let background = SKSpriteNode(color: .white, size: size)
        background.position = CGPoint(x: halfWidth, y: halfHeight)
        background.zPosition = -1
        paper.addChild(background)

        let label = SKLabelNode(text: "Paper")
        label.position = CGPoint(x: halfWidth, y: halfHeight)
        label.fontColor = .white
        label.fontSize = Constants.labelFontSize
        label.zPosition = Constants.labelZPosition
        paper.addChild(label)
    }

    // This method sets up gesture recognizers for the view
    func setupGestureRecognizers(in view: SKView) {
        let pinchRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        view.addGestureRecognizer(pinchRecognizer)
    }

    // This method handles pinch gestures
    @objc func handlePinch(gesture: NSMagnificationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        let scale = 1 + gesture.magnification
        let newScale = paper.xScale * scale
        paper.setScale(newScale)
        gesture.magnification = 0
    }
}

extension GameScene {

    // This method handles scroll events
    func handleScrollEvent(_ event: NSEvent) {
        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        let constrainedDeltaX = abs(deltaX) < Constants.threshold ? 0 : deltaX
        let constrainedDeltaY = abs(deltaY) < Constants.threshold ? 0 : deltaY
        let newPosition = CGPoint(x: paper.position.x + constrainedDeltaX, y: paper.position.y - constrainedDeltaY)
        paper.position = newPosition
    }
}
