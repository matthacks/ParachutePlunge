//
//  GameScene.swift
//  ParachutePlunge
//
//  Created by Matt Corrente on 3/1/18.
//  Copyright © 2018 Matt Corrente. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
import AVKit

struct PhysicsCategory {
    static let None:   UInt32 = 0
    static let All:    UInt32 = UInt32.max
    static let Coin:   UInt32 = 0b1         // 1
    static let BigCoin:UInt32 = 0b10        // 2
    static let Spike:  UInt32 = 0b11        // 3
    static let Enemy:  UInt32 = 0b100       // 4
    static let Player: UInt32 = 0b101       // 5
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    let player = spriteNodeWithSound(imageNamed: "player")
    let playerName = "player"
    let blockName = "block"
    let fallingName = "falling"
    let spikeName = "spike"
    let coinName = "coin"
    var motionManager = CMMotionManager()
    var destX: CGFloat = 0.0
    let swipeUp = UISwipeGestureRecognizer()
    let swipeDown = UISwipeGestureRecognizer()
    let swipeLeft = UISwipeGestureRecognizer()
    let swipeRight = UISwipeGestureRecognizer()
    var isGameOver = false
    var backgroundMusic: SKAudioNode!
    
    var worldNode: SKNode?
    var nodeTileHeight: CGFloat = 0.0
    var yOrgPosition: CGFloat?
    
    var cam: SKCameraNode = SKCameraNode()
    
    let coin1Sound = SKAudioNode(fileNamed: "coin1.mp3")
    let coin2Sound = SKAudioNode(fileNamed: "coin2.mp3")
    let coin3Sound = SKAudioNode(fileNamed: "coin3.mp3")
    let deathSound = SKAudioNode(fileNamed: "deathsound.mp3")

    class spriteNodeWithSound: SKSpriteNode {
        var spriteSound: SKAudioNode!
    }

    func initializeAudioPlayers(){
        coin1Sound.autoplayLooped = false
        self.addChild(coin1Sound)
        
        coin2Sound.autoplayLooped = false
        self.addChild(coin2Sound)
        
        coin3Sound.autoplayLooped = false
        self.addChild(coin3Sound)
        
        player.spriteSound = deathSound
        deathSound.autoplayLooped = false
        self.addChild(deathSound)
    }

    func playSound(audioNode: SKAudioNode) {
        audioNode.run(SKAction.play())
    }
    
    @objc func swipeUpPlayerJump(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:0, dy:500))
        }
        else{
            let gameScene:GameScene = GameScene(size: self.view!.bounds.size)
            let transition = SKTransition.fade(withDuration: 1.0)
            gameScene.scaleMode = SKSceneScaleMode.fill
            self.view!.presentScene(gameScene, transition: transition)
        }
    }
    
    @objc func swipeDownPlayerRushDown(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:0, dy:-250))
        }
    }
    
    @objc func swipeLeftMovePlayer(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:-250, dy:0))
        }
    }
    
    @objc func swipeRightMovePlayer(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:500, dy:0))
        }
    }
    
    override func didMove(to view: SKView) {
        
        initializeAudioPlayers()
        
        isGameOver = false
        
        let dictToSend: [String: String] = ["fileToPlay": "electroIndie" ]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayBackgroundSound"), object: self, userInfo:dictToSend) //posts the notification

        let backgroundNode = SKSpriteNode(imageNamed: "background1")
        backgroundNode.size = CGSize(width: self.frame.width, height: self.frame.height)
        backgroundNode.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundNode.zPosition = -20
        self.addChild(backgroundNode)
        
        // Setup dynamic background tiles
        // Image of left and right node must be identical
        let backgroundImage1 = SKSpriteNode(imageNamed: "background1")
        let backgroundImage2 = SKSpriteNode(imageNamed: "background2")
        let backgroundImage3 = SKSpriteNode(imageNamed: "background3")
        let backgroundImage4 = SKSpriteNode(imageNamed: "background1")
        
        worldNode = SKNode()
        self.addChild(worldNode!)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.fontColor = SKColor.black
        scoreLabel.text = "Score: 0"
        scoreLabel.zPosition = 15
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 0, y: size.height - 60)

        addChild(scoreLabel)
        
        //used for animating
        nodeTileHeight = backgroundImage1.frame.size.height
        yOrgPosition = 0
        backgroundImage1.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage1.position = CGPoint(x: 0, y: 0)
        backgroundImage1.zPosition = -10
        backgroundImage2.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage2.position = CGPoint(x: 0, y: nodeTileHeight)
        backgroundImage2.zPosition = -10
        backgroundImage3.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage3.position = CGPoint(x:0, y: nodeTileHeight * 2)
        backgroundImage3.zPosition = -10
        backgroundImage4.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage4.position = CGPoint(x:0, y: nodeTileHeight * 3)
        backgroundImage4.zPosition = -10
    
        // Add tiles to worldNode. worldNode is used to realize the scrolling
        worldNode!.addChild(backgroundImage1)
        worldNode!.addChild(backgroundImage2)
        worldNode!.addChild(backgroundImage3)
        worldNode!.addChild(backgroundImage4)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        motionManager.startAccelerometerUpdates()
        
        player.position = CGPoint(x: size.width/2, y: size.height*0.5)
        player.name = playerName
        player.physicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        player.physicsBody!.isDynamic = true
        player.physicsBody!.mass = 0.02
        player.physicsBody!.affectedByGravity = true
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        player.physicsBody!.contactTestBitMask = PhysicsCategory.All
        player.physicsBody!.usesPreciseCollisionDetection = true
        
        addChild(player)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
        swipeUp.addTarget(self, action: #selector(GameScene.swipeUpPlayerJump))
        swipeUp.direction = .up
        self.view!.addGestureRecognizer(swipeUp)
        
        swipeDown.addTarget(self, action: #selector(GameScene.swipeDownPlayerRushDown))
        swipeDown.direction = .down
        self.view!.addGestureRecognizer(swipeDown)
        
        swipeLeft.addTarget(self, action: #selector(GameScene.swipeLeftMovePlayer))
        swipeLeft.direction = .left
        self.view!.addGestureRecognizer(swipeLeft)
        
        swipeRight.addTarget(self, action: #selector(GameScene.swipeRightMovePlayer))
        swipeRight.direction = .right
        self.view!.addGestureRecognizer(swipeRight)
        
        cam.position = CGPoint(x: scene!.size.width / 2,
                               y: scene!.size.height / 2)
        addChild(cam)
        scene!.camera = cam
    
        // instantiates blocks
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addBlock),
                SKAction.wait(forDuration: 0.5)
                ])
        ))
        
        // setup random drops
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(dropStuff),
                SKAction.wait(forDuration: 3.0)
                ])
        ))
    }
    
    override func update(_ currentTime: CFTimeInterval){
        super.update(currentTime)
        
        self.enumerateChildNodes(withName: "falling") {
            node, stop in
            if (node is SKSpriteNode) {
                let sprite = node as! SKSpriteNode
                // Check if the node is not in the scene
                if (sprite.position.x < -sprite.size.width/2.0 || sprite.position.x > self.size.width+sprite.size.width/2.0
                    || sprite.position.y < sprite.size.height*0.75 || sprite.position.y > self.size.height+sprite.size.height/2.0) {
                    sprite.removeFromParent()
                }
            }
        }
        
        if (!isGameOver && (player.position.y < 40 ||
            (player.position.y > (scene?.size.height)! || player.position.x > (scene?.size.width)! || player.position.x < 0))) {
            gameOver()
        }
        
        //move background
        
        // calculate the new position
        let yNewPosition = worldNode!.position.y + (yOrgPosition! + 5)
        
        // Check if right end is reached
        if yNewPosition <= -(3 * nodeTileHeight) {
            worldNode!.position = CGPoint(x: 0, y: 0)
            // Check if left end is reached
        } else if yNewPosition >= 0 {
            worldNode!.position = CGPoint(x:0, y:  -(3 * nodeTileHeight))
        } else {
            worldNode!.position = CGPoint(x:0, y: yNewPosition)
        }
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func dropStuff(){
        //add coins to block 50% of the time
        switch Int(arc4random_uniform(4)) {
        case 0:
            if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
                dropBigCoin()
            }
        case 1:
            dropEnemy()
        case 2:
            dropAnchor()
        default: break
            //do nothing
        }
    }
    
    func dropBigCoin(){
        let coin = spriteNodeWithSound(imageNamed: "bigCoin")
        
        let actualX = random(min: coin.size.width/2, max: scene!.size.width - coin.size.height/2)
        coin.position.x = actualX
        coin.position.y = scene!.size.height - coin.size.height/2
        addChild(coin)
        
        coin.zPosition = 10
        coin.name = fallingName
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.frame.size)
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.frame.size)
        coin.physicsBody?.categoryBitMask = PhysicsCategory.BigCoin
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        coin.physicsBody!.isDynamic = true
        coin.physicsBody?.affectedByGravity = true
        coin.physicsBody?.mass = 0.01
        coin.spriteSound = coin1Sound
    }
    
    func dropEnemy(){
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = fallingName
        let actualX = random(min: enemy.size.width/2, max: scene!.size.width - enemy.size.height/2)
        enemy.position.x = actualX
        enemy.position.y = scene!.size.height - enemy.size.height/2
        addChild(enemy)
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.frame.size)
        enemy.physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        enemy.physicsBody!.contactTestBitMask = PhysicsCategory.All
        enemy.physicsBody!.isDynamic = true
        enemy.physicsBody?.affectedByGravity = true
        enemy.physicsBody?.mass = 0.07
    }
    
    func dropAnchor(){
        let anchor = SKSpriteNode(imageNamed: "anchor")
        anchor.name = fallingName
        let actualX = random(min: anchor.size.width/2, max: scene!.size.width - anchor.size.height/2)
        anchor.position.x = actualX
        anchor.position.y = scene!.size.height - anchor.size.height/2
        addChild(anchor)
        anchor.physicsBody = SKPhysicsBody(rectangleOf: anchor.frame.size)
        anchor.physicsBody!.isDynamic = true
        anchor.physicsBody?.affectedByGravity = true
        anchor.physicsBody?.mass = 0.07
    }
    
    func addCoinToBlock(centerXDestination: CGFloat, actionMoveDone: SKAction, block: SKSpriteNode, duration: CGFloat, blockDestHeight: CGFloat){
        
        let coin = spriteNodeWithSound(imageNamed: "coin")
        
        let destHeight = blockDestHeight + coin.size.height*1.5
        
        var coinMove = SKAction.move(to: CGPoint(x:  centerXDestination, y: destHeight), duration: TimeInterval(duration))
    
        coin.position = CGPoint(x: block.position.x, y: block.position.y + coin.size.height*1.5)
        addChild(coin)
        coin.zPosition = 10
        coin.name = coinName
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.frame.size)
        coin.physicsBody!.isDynamic = false
        coin.physicsBody!.restitution = 0
        coin.physicsBody?.categoryBitMask = PhysicsCategory.Coin
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        coin.physicsBody?.collisionBitMask = PhysicsCategory.None
        coin.spriteSound = coin1Sound
        coin.run(SKAction.sequence([coinMove, actionMoveDone]))
        
        let coin2 = coin.copy() as! spriteNodeWithSound
        coinMove = SKAction.move(to: CGPoint(x:  centerXDestination - coin.size.width*1.5 , y: destHeight), duration: TimeInterval(duration))
        coin2.position = CGPoint(x: coin.position.x - coin.size.width*1.5, y: coin.position.y)
        coin2.run(SKAction.sequence([coinMove, actionMoveDone]))
        coin2.spriteSound = coin2Sound
        addChild(coin2)
        
        let coin3 = coin.copy() as! spriteNodeWithSound
        coinMove = SKAction.move(to: CGPoint(x:  centerXDestination + coin.size.width*1.5 , y: destHeight), duration: TimeInterval(duration))
        coin3.position = CGPoint(x: coin.position.x + coin.size.width*1.5, y: coin.position.y)
        coin3.run(SKAction.sequence([coinMove, actionMoveDone]))
        coin3.spriteSound = coin3Sound
        addChild(coin3)
    }
    
    func addSpikeToBottomOfBlock(centerXDestination: CGFloat, actionMoveDone: SKAction, block: SKSpriteNode, duration: CGFloat, blockDestHeight: CGFloat){
        let spike = SKSpriteNode(imageNamed: "spikeDown")
        let destHeight = blockDestHeight - spike.size.height*1.25
        var spikeMove = SKAction.move(to: CGPoint(x: centerXDestination, y: destHeight), duration: TimeInterval(duration))
        spike.position = CGPoint(x: block.position.x, y: block.position.y - spike.size.height*1.5)
        addChild(spike)
        spike.zPosition = 10
        spike.name = spikeName
        spike.physicsBody = SKPhysicsBody(texture: spike.texture!, size: spike.size)
        spike.physicsBody?.categoryBitMask = PhysicsCategory.Spike
        spike.physicsBody?.contactTestBitMask = PhysicsCategory.All
        spike.physicsBody!.isDynamic = false
        spike.run(SKAction.sequence([spikeMove, actionMoveDone]))
        
        let spike2 = spike.copy() as! SKSpriteNode
        spikeMove = SKAction.move(to: CGPoint(x:  centerXDestination - spike.size.width*1.05 , y: destHeight), duration: TimeInterval(duration))
        spike2.position = CGPoint(x: spike.position.x - spike.size.width*1.25, y: spike.position.y)
        spike2.run(SKAction.sequence([spikeMove, actionMoveDone]))
        addChild(spike2)
        
        let spike3 = spike.copy() as! SKSpriteNode
        spikeMove = SKAction.move(to: CGPoint(x: centerXDestination + spike.size.width*1.05 , y: destHeight), duration: TimeInterval(duration))
        spike3.position = CGPoint(x: spike.position.x + spike.size.width*1.25, y: spike.position.y)
        spike3.run(SKAction.sequence([spikeMove, actionMoveDone]))
        addChild(spike3)
    }
    
    func addSpikeToTopOfBlock(centerXDestination: CGFloat, actionMoveDone: SKAction, block: SKSpriteNode, duration: CGFloat, blockDestHeight: CGFloat){
        let spike = SKSpriteNode(imageNamed: "spikeUp")
        let destHeight = blockDestHeight + spike.size.height*1.25
        
        var spikeMove = SKAction.move(to: CGPoint(x: centerXDestination, y: destHeight), duration: TimeInterval(duration))
        spike.position = CGPoint(x: block.position.x, y: block.position.y + spike.size.height*1.5)
        addChild(spike)
        spike.zPosition = 10
        spike.name = spikeName
        spike.physicsBody = SKPhysicsBody(texture: spike.texture!, size: spike.size)
        spike.physicsBody?.categoryBitMask = PhysicsCategory.Spike
        spike.physicsBody?.contactTestBitMask = PhysicsCategory.All
        spike.physicsBody!.isDynamic = false
        spike.run(SKAction.sequence([spikeMove, actionMoveDone]))
        
        let spike2 = spike.copy() as! SKSpriteNode
        spikeMove = SKAction.move(to: CGPoint(x:  centerXDestination - spike.size.width*1.25 , y: destHeight), duration: TimeInterval(duration))
        spike2.position = CGPoint(x: spike.position.x - spike.size.width*1.25, y: spike.position.y)
        spike2.run(SKAction.sequence([spikeMove, actionMoveDone]))
        addChild(spike2)
        
        let spike3 = spike.copy() as! SKSpriteNode
        spikeMove = SKAction.move(to: CGPoint(x:  centerXDestination + spike.size.width*1.05 , y: destHeight), duration: TimeInterval(duration))
        spike3.position = CGPoint(x: spike.position.x + spike.size.width*1.05, y: spike.position.y)
        spike3.run(SKAction.sequence([spikeMove, actionMoveDone]))
        addChild(spike3)
    }
    
    func addBlock() {
        
        //do this 1 out of every 2 times
        if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
            
            let block = SKSpriteNode(imageNamed: "block")
            
            var actionMove: SKAction
            let duration = CGFloat(2.0)
            let blockStartHeight = -block.size.height + (random(min: CGFloat(0.0), max: CGFloat(5.0)) * block.size.height)
            let blockDestHeight = scene!.size.height + block.size.height*1.5 - blockStartHeight
            
            
            let xStart = random(min: -block.size.width, max: scene!.size.width + block.size.width)
            let xDest = random(min: -block.size.width, max: scene!.size.width + block.size.width)
            
 
            //create the block
            block.position = CGPoint(x: xStart, y: blockStartHeight)
            addChild(block)
            actionMove = SKAction.move(to: CGPoint(x: xDest, y: blockDestHeight), duration: TimeInterval(duration))
            
            block.name = blockName
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.isDynamic = false
            let actionMoveDone = SKAction.removeFromParent()
            block.run(SKAction.sequence([actionMove, actionMoveDone]))
            
            // add spike to block block 1/3 of the time
            if(Int(arc4random_uniform(75)) < 25){
                addSpikeToBottomOfBlock(centerXDestination: xDest, actionMoveDone: actionMoveDone, block: block, duration: duration, blockDestHeight: blockDestHeight)
            }

            //add coins to block 50% of the time
            if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
                addCoinToBlock(centerXDestination: xDest, actionMoveDone: actionMoveDone, block: block, duration: duration, blockDestHeight: blockDestHeight)
            }
            else{
                if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
                    addSpikeToTopOfBlock(centerXDestination: xDest, actionMoveDone: actionMoveDone, block: block, duration: duration, blockDestHeight: blockDestHeight)
                }
            }
            
        }
    }
    
    func coinCollidedWithPlayer(coin: spriteNodeWithSound) {
        coin.spriteSound.run(SKAction.play())
        coin.removeFromParent()
        score = score+1;
    }
    
    func bigCoinCollidedWithPlayer(coin: spriteNodeWithSound) {
        coin.spriteSound.run(SKAction.play())
        coin.removeFromParent()
        score = score+3;
    }
    
    func spikeCollidedWithEnemy(enemy: SKSpriteNode) {
        enemy.removeFromParent()
    }
    
    func gameOver() {
        
        let highScore = SKLabelNode(fontNamed:"Chalkduster")
        if(score > UserDefaults.standard.value(forKey: "highScore") as! Int){
            UserDefaults.standard.setValue(score, forKey:"highScore")
            highScore.text = ("New High Score: " + String(score))
        }
        else{
        highScore.text = "High Score: " + String(UserDefaults.standard.value(forKey: "highScore") as! Int)
        }
        highScore.fontColor = SKColor.black
        highScore.fontSize = 20
        highScore.position = CGPoint(x: size.width * 0.5, y: size.height * 0.40)
        highScore.zPosition = 20
        self.addChild(highScore)
        
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Game Over!"
        myLabel.fontColor = SKColor.black
        myLabel.fontSize = 30
        myLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.65)
        myLabel.zPosition = 20
        self.addChild(myLabel)
        
        let label = SKLabelNode(fontNamed:"Chalkduster")
        label.text = "(swipe up to play again)"
        label.fontColor = SKColor.black
        label.fontSize = 20
        label.zPosition = 20
        label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.60)
        self.addChild(label)
        
        isGameOver = true
        player.spriteSound.run(SKAction.play())
        player.removeFromParent()
    }

    
    func didBegin(_ contact: SKPhysicsContact) {
        // switch the firstBody to be the lowerValue
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask == PhysicsCategory.Coin) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
            if let coin = firstBody.node as? SKSpriteNode {
                coinCollidedWithPlayer(coin: coin as! GameScene.spriteNodeWithSound)
            }
        }
        else if ((firstBody.categoryBitMask == PhysicsCategory.BigCoin) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
            if let coin = firstBody.node as? SKSpriteNode {
                bigCoinCollidedWithPlayer(coin: coin as! GameScene.spriteNodeWithSound)
            }
        }
            else if ((firstBody.categoryBitMask == PhysicsCategory.Spike) &&
                (secondBody.categoryBitMask == PhysicsCategory.Enemy)) {
                if let enemy = secondBody.node as? SKSpriteNode {
                    spikeCollidedWithEnemy(enemy: enemy)
                }
            }
            else if ((firstBody.categoryBitMask == PhysicsCategory.Enemy) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                if(!isGameOver){
                    gameOver()
                }
             }
            else if ((firstBody.categoryBitMask == PhysicsCategory.Spike) &&
                (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                //todo - figure out why this is repeatedly getting called
                //this should not be reapeating...adding temp fix
                if(!isGameOver){
                    gameOver()
                }
            }
    }

}
