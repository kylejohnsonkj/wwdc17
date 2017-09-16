//: Playground - noun: a place where people can play

// March Madness - WWDC '17 entry by Kyle Johnson
// swipe up on the ball and shoot a basket!

import UIKit
import SpriteKit
import PlaygroundSupport
import AVFoundation

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Ball: UInt32 = 1
    static let Basket: UInt32 = 2
    static let Trigger: UInt32 = 4
}

// global instances
var audioPlayer = AVAudioPlayer()
var spotlightLeft: SKSpriteNode?
var spotlightRight: SKSpriteNode?
var ballHitTrigger = false
var spotlightsOn = false

// sound effects
let buzzerSound = SKAction.playSoundFileNamed("buzzer.wav", waitForCompletion: false)
let whooshSound = SKAction.playSoundFileNamed("whoosh.wav", waitForCompletion: false)
let cheerSound = SKAction.playSoundFileNamed("cheer.wav", waitForCompletion: false)

class BallNode: SKLabelNode {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // keep track of beginning of drag gesture
    var beginDrag: CGPoint?
    
    override init() {
        super.init()
        
        // create the basketball
        text = "🏀"
        fontSize = 200
        
        // add physics properties to ball
        physicsBody = SKPhysicsBody(circleOfRadius: 95, center: CGPoint(x: 0, y: 75))
        physicsBody?.affectedByGravity = false
        physicsBody?.restitution = 0.8
        physicsBody?.categoryBitMask =  PhysicsCategory.Ball
        physicsBody?.collisionBitMask = PhysicsCategory.Basket
        appearBeforeRim = true
    }
    
    // makes it appear that the ball goes inside the rim and net
    var appearBeforeRim: Bool {
        set { zPosition = newValue ? 1 : -1 }
        get { return zPosition == 1 }
    }
    
    // sets first touch point as beginDrag
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches
        guard beginDrag == nil else { return }
        beginDrag = touches.first?.location(in: self)
    }
    
    // sets the end point of drag and calls shoot w/ points
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let start = beginDrag else { return }
        let end = touches.first!.location(in: self)
        shoot(start, to: end)
        beginDrag = nil
    }
    
    // shoots ball in direction of vector based on player's drag
    func shoot(_ from: CGPoint, to: CGPoint) {
        let dx = (to.x - from.x) / 2.5
        let dy = to.y - from.y
        let norm = sqrt(pow(dx, 2) + pow(dy, 2))
        let base: CGFloat = 2000
        
        let impulse = CGVector(dx: base * (dx / norm), dy: base * (dy / norm))
        physicsBody?.applyImpulse(impulse)
        physicsBody?.applyAngularImpulse(CGFloat(M_PI) / 100)
        physicsBody?.affectedByGravity = true
        
        let scale: CGFloat = 0.5
        let scaleDuration: TimeInterval = 1.1
        run(SKAction.scale(by: scale, duration: scaleDuration))
        
        // begin playing music
        audioPlayer.play()
        
        // fancy spotlights (why not?)
        if spotlightsOn == false {
            spotlightLeft?.texture = SKTexture(imageNamed: "spotlight-left.png")
            spotlightRight?.texture = SKTexture(imageNamed: "spotlight-right.png")
            let rotate1 = SKAction.rotate(byAngle: CGFloat(M_PI) / CGFloat(4.0), duration: 1.0)
            let rotate2 = SKAction.rotate(byAngle: CGFloat(-M_PI) / CGFloat(4.0), duration: 1.0)
            spotlightLeft?.run(SKAction.repeatForever((SKAction.sequence([rotate1, rotate2]))))
            spotlightRight?.run(SKAction.repeatForever((SKAction.sequence([rotate1.reversed(), rotate2.reversed()]))))
            spotlightsOn = true
        }
    }
    
    // after shot is made, reset ball
    func reset(ballPosition: CGPoint) {
        physicsBody?.affectedByGravity = false
        physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        physicsBody?.angularVelocity = 0
        position = ballPosition
        zPosition = 1
        zRotation = 0
        xScale = 1
        yScale = 1
        appearBeforeRim = true
    }
}

class Basket: SKNode {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // basket attributes
    let rimWidth: CGFloat = 200
    let rimHeight: CGFloat = 10
    var rim: SKShapeNode?
    var bb: SKSpriteNode?
    var net: SKSpriteNode?
    
    override init() {
        super.init()
        
        createRim()
        initScoreTrigger()
        drawBackboard()
        drawNet()
    }
    
    func createRim() {
        rim = SKShapeNode(rect: CGRect(x: 0, y: 0, width: rimWidth, height: 2 * rimHeight), cornerRadius: 8)
        rim!.fillColor = UIColor(red: 234/255, green: 104/255, blue: 68/255, alpha: 1.0)
        
        // add physics body to rim
        let l = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 2 * rimHeight), to: CGPoint(x: 3 * rimHeight, y: 2 * rimHeight))
        let r = SKPhysicsBody(edgeFrom: CGPoint(x: rimWidth - 3 * rimHeight, y: 2 * rimHeight), to: CGPoint(x: rimWidth, y: 2 * rimHeight))
        rim!.physicsBody = SKPhysicsBody(bodies: [l, r])
        rim!.physicsBody?.affectedByGravity = false
        rim!.physicsBody?.isDynamic = false
        
        rimEnabled = false
        addChild(rim!)
    }
    
    // used to trigger score
    var trigger: SKNode?
    
    // add collision info to trigger
    func initScoreTrigger() {
        trigger = SKNode()
        
        // add physics body to trigger
        let phy = SKPhysicsBody(circleOfRadius: 4 * rimHeight, center: CGPoint(x: rimWidth / 2, y: -rimWidth / 3))
        phy.affectedByGravity = false
        phy.isDynamic = false
        phy.collisionBitMask = PhysicsCategory.None
        phy.contactTestBitMask = PhysicsCategory.Ball
        phy.categoryBitMask = PhysicsCategory.Trigger
        trigger!.physicsBody = phy
        
        addChild(trigger!)
    }
    
    // load fancy backboard
    func drawBackboard() {
        bb = SKSpriteNode(imageNamed: "backboard.png")
        bb!.physicsBody?.affectedByGravity = false
        bb!.zPosition = -2
        bb!.setScale(1.3)
        bb!.position = CGPoint(x: 98, y: 108)
        addChild(bb!)
    }
    
    // load even fancier net
    func drawNet() {
        net = SKSpriteNode(imageNamed: "net.png")
        net!.physicsBody?.affectedByGravity = false
        net!.setScale(0.85)
        net!.position = CGPoint(x: 102, y: -85)
        addChild(net!)
    }
    
    // only enable ball collision with rim once ball is over rim
    var rimEnabled: Bool {
        set {
            rim?.physicsBody?.collisionBitMask = newValue ? PhysicsCategory.Ball : PhysicsCategory.None
            rim?.physicsBody?.categoryBitMask = newValue ? PhysicsCategory.Basket : PhysicsCategory.None
        }
        get {
            return rim?.physicsBody?.collisionBitMask == PhysicsCategory.Ball
        }
    }
}

class MarchMadnessScene: SKScene, SKPhysicsContactDelegate {
    
    var didMakeScene: Bool = false
    var ball: BallNode?
    var basket: Basket?
    var scoreText: SKLabelNode?
    var score: Int = 0 {
        didSet {
            scoreText?.text = "SCORE: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        guard !didMakeScene else { return }
        createScene()
        didMakeScene = true
    }
    
    func createScene() {
        // load background
        let background = SKSpriteNode(imageNamed: "bg.png")
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        background.size.width = frame.width
        background.size.height = frame.height
        background.zPosition = -3
        addChild(background)
        
        // load left spotlight (initially off)
        spotlightLeft = SKSpriteNode(imageNamed: "spotlight-left-off.png")
        spotlightLeft?.position = CGPoint(x: 0, y: frame.size.height)
        spotlightLeft?.setScale(0.75)
        spotlightLeft?.zRotation = CGFloat(-M_PI) / 8.0
        addChild(spotlightLeft!)
        
        // load right spotlight (initially off)
        spotlightRight = SKSpriteNode(imageNamed: "spotlight-right-off.png")
        spotlightRight?.position = CGPoint(x: frame.size.width, y: frame.size.height)
        spotlightRight?.setScale(0.75)
        spotlightRight?.zRotation = CGFloat(M_PI) / 8.0
        addChild(spotlightRight!)

        addChild(ballNode())
        addChild(basketNode())
        addChild(scoreLabel())
        
        self.scaleMode = .aspectFit
        physicsWorld.contactDelegate = self
    }
    
    // create and get ball node
    func ballNode() -> SKLabelNode {
        let node = BallNode()
        ball = node
        node.position = ballPosition()
        node.isUserInteractionEnabled = true
        return node
    }
    
    // create and get basket node
    func basketNode() -> Basket {
        let basket = Basket()
        self.basket = basket
        basket.position = CGPoint(x: frame.midX - basket.rimWidth / 2, y: 700)
        return basket
    }
    
    // create and get score node
    func scoreLabel() -> SKLabelNode {
        let scoreLabel = SKLabelNode()
        scoreText = scoreLabel
        scoreLabel.fontSize = 55
        scoreLabel.fontName = "Futura Condensed Medium"
        scoreLabel.fontColor = UIColor(red: 99/255, green: 159/255, blue: 255/255, alpha: 1.0)
        scoreLabel.text = "SWIPE ON BALL TO SHOOT"
        scoreLabel.zPosition = -2
        scoreLabel.position = CGPoint(x: frame.midX, y: 450)
        return scoreLabel
    }
    
    // get ball position
    func ballPosition() -> CGPoint {
        return CGPoint(x: frame.midX, y: 50)
    }
    
    // reset ball for next shot
    func resetBall() {
        ball?.reset(ballPosition: ballPosition())
        basket?.rimEnabled = false
        
        // pick random direction for basket to go
        let direction = Int(arc4random_uniform(2))
        
        if !ballHitTrigger {
            // if game needs to reset, center basket
            basket?.run(SKAction.move(to: CGPoint(x: frame.midX - (basket?.rimWidth)! / 2, y: 700), duration: 1.0))
        } else {
            // move by random distance in whatever direction (L || R)
            switch direction {
            case 0:
                let distance = -Int(arc4random_uniform(UInt32((basket?.position.x)! - 200)))
                basket?.run(SKAction.moveBy(x: CGFloat(distance), y: 0, duration: 1.0))
            case 1:
                let distance = Int(arc4random_uniform(UInt32(484 - (basket?.position.x)!)))
                basket?.run(SKAction.moveBy(x: CGFloat(distance), y: 0, duration: 1.0))
            default:
                print("how is Craig Federighi's hair so perfect?")
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {

        // check for when ball goes above rim
        if basket!.position.y < ball!.position.y {
            // if so, enable the rim physics and set lower zPosition of the ball
            basket?.rimEnabled = true
            ball?.appearBeforeRim = false
        }
        if ball!.position.y < -300 {
            // when ball falls off screen (Game Over!)
            if ballHitTrigger == false {
                run(buzzerSound)
                audioPlayer.stop()
                score = 0
                
                // retract spotlights
                spotlightLeft?.removeAllActions()
                spotlightRight?.removeAllActions()
                spotlightLeft?.run(SKAction.rotate(toAngle: CGFloat(-M_PI) / 8.0, duration: 1.0))
                spotlightRight?.run(SKAction.rotate(toAngle: CGFloat(M_PI) / 8.0, duration: 1.0))
                spotlightLeft?.texture = SKTexture(imageNamed: "spotlight-left-off.png")
                spotlightRight?.texture = SKTexture(imageNamed: "spotlight-right-off.png")
                spotlightsOn = false
            }
            
            // put ball at bottom again
            resetBall()
            ballHitTrigger = false
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // since either the ball or trigger could be the first body, check both possible cases
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        if ball?.appearBeforeRim == false {
            // when ball is above rim and ball hits trigger
            if ((firstBody.categoryBitMask & PhysicsCategory.Ball != 0) &&
                (secondBody.categoryBitMask & PhysicsCategory.Trigger != 0)) {
                ballHitTrigger = true
                run(whooshSound)
                
                // animations for score text
                let scale1 = SKAction.scale(by: 1.4, duration: 0.3)
                let scale2 = SKAction.scale(by: 1/1.4, duration: 0.3)
                scoreText?.run(SKAction.sequence([scale1, scale2]))
                
                // animations for net
                let scale3 = SKAction.scaleY(to: 0.5, duration: 0.3)
                let scale4 = SKAction.scaleY(to: 0.85, duration: 0.3)
                let scale5 = SKAction.moveBy(x: 0, y: 36, duration: 0.3)
                let scale6 = SKAction.moveBy(x: 0, y: -36, duration: 0.3)
                basket?.net?.run(SKAction.sequence([scale3, scale4]))
                basket?.net?.run(SKAction.sequence([scale5, scale6]))
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        guard basket!.rimEnabled else { return }
        
        // update score
        score += 1
        
        // play cheer sfx every 3 baskets
        if score % 3 == 0 {
            run(cheerSound)
        }
    }
}

class MarchMadnessVC: UIViewController {}

var vc = MarchMadnessVC()
let view = SKView(frame: vc.view.frame)
vc.view = view

// required for assistant editor live view
PlaygroundPage.current.liveView = vc

/* TESTING */
view.showsFPS = true
view.showsNodeCount = true
//view.showsPhysics = true

let size = CGSize(width: 768, height: 1024)
let scene = MarchMadnessScene(size: size)
view.presentScene(scene)

// March Madness background music
let bgMusic = Bundle.main.url(forResource: "music", withExtension: "mp3")!

do {
    try audioPlayer = AVAudioPlayer(contentsOf: bgMusic)
    audioPlayer.prepareToPlay()
    audioPlayer.numberOfLoops = -1
    audioPlayer.volume = 0.5
} catch {
    print("seriously... he really is Hair Force One!")
}
