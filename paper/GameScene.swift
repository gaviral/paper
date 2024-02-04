//
//  GameScene.swift
//  paper
//
//  Created by Aviral Garg on 2023-12-30.
//

import SpriteKit
import OpenAI

struct testing {
    static var openAI: Bool = false
}

struct Constants {
    static let titleLabelFontSize: CGFloat = 48
    static let treeNodeLabelFontSize: CGFloat = 10
    static let labelZPosition: CGFloat = 1
    static let threshold: CGFloat = 0.0
}

class GameScene: SKScene {
    private let paper = SKNode()
    private var halfWidth: CGFloat { size.width / 2 }
    private var halfHeight: CGFloat { size.height / 2 }
    private var node_positions = [CGPoint]() // array to store the positions of the nodes
    private var new_node_x_position: CGFloat = 0 // variable to store the x position of the next node;
    private var new_node_y_position: CGFloat = 0 // variable to store the y position of the next node; incremented by 50 each time a new node is added
    private var textField: NSTextField = NSTextField()

    override func didMove(to view: SKView) {
        setupWorldNode()
        setupGestureRecognizers(in: view)
        fetchNotes()

        if testing.openAI {
            // Use a task to handle async calls
            Task {
                await openAI()
            }
        }
    }
}

private extension GameScene {

    // This method fetches the notes from the server
    func fetchNotes() {
        let urlString = "https://raw.githubusercontent.com/gaviral/map/main/index.html"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let htmlContent = String(data: data, encoding: .utf8)
                // add label for only the first line of the html content
                var node_text = htmlContent?.components(separatedBy: "\n")[0]

                // add labels for the rest of the html content
                var i = 1
                for node_text in htmlContent!.components(separatedBy: "\n").dropFirst() {
                    self.addLabel(text: node_text, x: self.new_node_x_position, y: self.new_node_y_position)
                    i += 1
                    if i > 10 {
                        break
                    }
                }
            } catch {
                print(error)
            }
        }
    }

    // This method calls openAI API
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

    // This method adds a label to the world node
    func addLabel(text: String, x: CGFloat, y: CGFloat, frontSize: CGFloat = Constants.treeNodeLabelFontSize) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.position = CGPoint(x: x, y: y)
        label.fontColor = .white
        label.fontSize = frontSize
        label.zPosition = Constants.labelZPosition
        paper.addChild(label)
        node_positions.append(label.position)
        new_node_y_position -= 15
        return label
    }
    
    // This method adds a background to the world node at the given coordinates with a given size
    // Usage: addBackground(x: 0, y: 0, width: size.width / 5 , height: size.height / 5)
    func addBackground(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let background = SKSpriteNode(color: .white, size: CGSize(width: width, height: height))
        background.position = CGPoint(x: x, y: y)
        background.zPosition = -1
        paper.addChild(background)
    }

    // This method sets up gesture recognizers for the view
    func setupGestureRecognizers(in view: SKView) {
        let pinchRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        view.addGestureRecognizer(pinchRecognizer)
    }

    // This method resizes the paper node when the view is resized
    // override func didChangeSize(_ oldSize: CGSize) {
    //     // TODO: This method is not tested yet
    //     paper.position = CGPoint(x: halfWidth, y: halfHeight)
    // }

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
