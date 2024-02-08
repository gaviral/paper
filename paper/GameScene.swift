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

class TreeNode<T> {
    var value: T
    var depth = 0
    var children: [TreeNode] = []
    weak var parent: TreeNode?

    init(value: T) {
        self.value = value
    }

    func addChild(_ node: TreeNode<T>) {
        children.append(node)
        node.parent = self
    }
}


class GameScene: SKScene {
    private let paper = SKNode()
    private var halfWidth: CGFloat { size.width / 2 }
    private var halfHeight: CGFloat { size.height / 2 }
    private var node_positions = [CGPoint]() // array to store the positions of the nodes
    private var new_node_x_position: CGFloat = 0 // variable to store the x position of the next node;
    private var new_node_y_position: CGFloat = 0 // variable to store the y position of the next node; incremented by 50 each time a new node is added
    private var textField: NSTextField = NSTextField()
    private var markdownLines = [String]()  // array to store the lines of the markdown file
    private var stack: [TreeNode<String>] = [TreeNode<String>(value: "root")] // stack to keep track of the last node at each level of indentation
    // number of times "---" occurs in the markdown file
    private var numberOfDashes: Int = 0
    

    override func didMove(to view: SKView) {
        setupWorldNode()
        setupGestureRecognizers(in: view)
        fetchNotes(urlString: "https://raw.githubusercontent.com/gaviral/map/main/index.html")

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
    func fetchNotes(urlString: String) {
        let urlString = urlString
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let htmlContent = String(data: data, encoding: .utf8)
                var i = 1

                // line number of the line containing <script type="text/template"> and it's corresponding </script> tag. everything in between these tags is the markdown content
                var startLine: Int = 0
                var endLine: Int = 0

                // iterate through the lines of the html content
                for line in htmlContent!.components(separatedBy: "\n") {
                    if line.contains("<script type=\"text/template\">") {
                        startLine = i
                    }
                    if line.contains("</script>") {
                        endLine = i
                    }
                    i += 1
                }

                // extract the markdown content from the html content
                let markdownContent = htmlContent!.components(separatedBy: "\n")[startLine...endLine]
                for line in markdownContent {
                    markdownLines.append(line)
                }

                // first few lines of the markdown content contain some settings that we don't need
                // line before settings is "---" with some spaces before it
                // line after settings is "---" with some spaces before it
                // store the settings in a separate array and remove them from the markdown content
                var settings = [String]()
                var j = 0
                for line in markdownLines {
                    if line.contains("---") {
                        numberOfDashes += 1
                    }
                    if numberOfDashes == 2 {
                        break
                    }
                    settings.append(line)
                    j += 1
                }
                markdownLines.removeSubrange(0...j)

                // print settings
                for setting in settings {
                    print(setting)
                }

                print("Markdown content after removing settings:")

                i = 0

                for line in self.markdownLines {

                    // store line number, number of spaces before the line, and the line
                    let node_number = i
                    let node_depth = line.prefix(while: { $0 == " " }).count/2
                    let node_content = line.trimmingCharacters(in: .whitespaces)
                    
                    // print line_number, number of spaces before the line, and the line
                    print(node_number, node_depth, node_content)

                    // add the line to the tree (stack already contains the root node)
                    // if the line is at the same level as the last line, add it to the same parent
                    let stack_last_depth = stack.last?.depth

                    if node_depth == stack_last_depth {
                        stack.last?.addChild(TreeNode<String>(value: node_content))
                    }
                    // if the line is at a deeper level than the last line, add it as a child of the last line
                    else if node_depth > stack_last_depth! {
                        stack.last?.addChild(TreeNode<String>(value: node_content))
                    }
                    // if the line is at a shallower level than the last line, pop the stack back to the parent level and add it there
                    else {
                        stack = Array(stack.prefix(node_depth + 1))
                        stack.last?.addChild(TreeNode<String>(value: node_content))
                    }

                    // push this node onto the stack
                    stack.append(TreeNode<String>(value: node_content))
                    
                    i += 1
                }

                // print the tree iterative bfs
                print("Iterative BFS:")
                var queue = [TreeNode<String>]()
                queue.append(stack[0])
                while !queue.isEmpty {
                    let node = queue.removeFirst()
                    print(node.value)
                    // print first 5 children of the node
                    for i in 0..<min(5, node.children.count) {
                        print("a:", node.children[i].value)
                    }
                    queue.append(contentsOf: node.children)
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
                let query = CompletionsQuery(
                    model: .textDavinci_003,
                    prompt: "What is 42?",
                    temperature: 0,
                    maxTokens: 100,
                    topP: 1,
                    frequencyPenalty: 0,
                    presencePenalty: 0,
                    stop: ["\\n"]
                )
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

// extension GameScene {
//     func parseMarkdownToTree(_ markdown: String) -> TreeNode<String>? {
//         // Split the markdown content into lines
//         let lines = markdown.components(separatedBy: "\n")
        
//         // Placeholder for the root of the tree
//         let root = TreeNode<String>(value: "root")
        
//         // Stack to keep track of the last node at each level of indentation
//         var stack: [TreeNode<String>] = [root]
        
//         for line in lines {
//             // Determine the level of indentation
//             let level = line.prefix(while: { $0 == " " || $0 == "\t" }).count / 4 // assuming 4 spaces per indent level
            
//             // Extract the actual content without leading spaces or list markers
//             let content = line.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "-*"))
            
//             // Create a new node for this line
//             let node = TreeNode<String>(value: content)
            
//             // If the current level is deeper than the stack, it means this is a child of the last item
//             if level >= stack.count {
//                 stack.last?.addChild(node)
//             } else {
//                 // If we're at a shallower level, pop the stack back to the parent level and add it there
//                 stack = Array(stack.prefix(level + 1))
//                 stack.last?.addChild(node)
//             }
            
//             // Push this node onto the stack
//             stack.append(node)
//         }
        
//         return root.children.isEmpty ? nil : root
//     }
// }
