import UIKit
import SceneKit
import ARKit

class MainViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    var start: CGPoint?
    var end: CGPoint?
    var motherBallNode: BallNode!
    var targetBallNode: BallNode!
    let ballRadius: Float = 0.02
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        sceneView.addGestureRecognizer(panGesture)
        
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view
        
        if panGesture.state == .began {
            start = panGesture.translation(in: view)
        }
        
        if panGesture.state == .ended {
            end = panGesture.translation(in: view)
            
            guard let startPoint = start, let endPoint = end else { return }
            
            guard let start3D = sceneView.hitTest(startPoint, types: .existingPlane).first,
                let end3D = sceneView.hitTest(endPoint, types: .existingPlane).first else { return }
            
            let end3DTranslation = end3D.worldTransform.columns.3
            let start3DTranslation = start3D.worldTransform.columns.3
            let ballDirection = SCNVector3(end3DTranslation.x - start3DTranslation.x,
                                           0,
                                           end3DTranslation.z - start3DTranslation.z).normalized
            let speed: Float = 0.2
            motherBallNode.runAction(SCNAction.moveBy(x: CGFloat(ballDirection.x * speed * 3),
                                                      y: 0,
                                                      z: CGFloat(ballDirection.z * speed * 3),
                                                      duration: 3), forKey: "Move")
            //let speed = sqrt((end3DTranslation.x - start3DTranslation.x).power(exponential: 2) + (end3DTranslation.y - start3DTranslation.y).power(exponential: 2))
            motherBallNode.moved(ballSpeed: speed, ballDirection: ballDirection)
            //            print("start: \(startPoint.x) \(startPoint.y)")
            //            print("end: \(endPoint.x) \(endPoint.y))")
            //
            //            print("\(start3D.worldTransform.columns.3)")
            //            print("\(end3D.worldTransform.columns.3)")
        }
        
    }
}

extension MainViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        setupPlane(planeAnchor: planeAnchor, node: node)
        setupMotherBall(planeAnchor: planeAnchor, node: node)
        //setupTargetBall(planeAnchor: planeAnchor, node: node)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
}

extension MainViewController {
    private func setupPlane(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.green
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode()
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.position = SCNVector3(planeAnchor.center.x,
                                        0,
                                        planeAnchor.center.z)
        planeNode.geometry = plane
        
        node.addChildNode(planeNode)
        
        let wallNegtiveZ = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(ballRadius * 2))
        let wallNegativeZMaterial = SCNMaterial()
        wallNegativeZMaterial.diffuse.contents = UIColor.blue
        wallNegtiveZ.materials = [wallNegativeZMaterial]
        
        let wallNegativeZNode = SCNNode()
        wallNegativeZNode.position = SCNVector3(planeAnchor.center.x,
                                                ballRadius,
                                                planeAnchor.center.z - planeAnchor.extent.z / 2)
        wallNegativeZNode.geometry = wallNegtiveZ
        wallNegativeZNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallNegtiveZ, options: nil))
        wallNegativeZNode.physicsBody?.categoryBitMask = 2
        wallNegativeZNode.physicsBody?.contactTestBitMask = 1
        wallNegativeZNode.name = "-Z wall"
        
        node.addChildNode(wallNegativeZNode)
        
        let wallPositiveZ = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(ballRadius * 2))
        let wallPositiveZMaterial = SCNMaterial()
        wallPositiveZMaterial.diffuse.contents = UIColor.blue
        wallPositiveZ.materials = [wallNegativeZMaterial]
        
        let wallPositiveZNode = SCNNode()
        wallPositiveZNode.position = SCNVector3(planeAnchor.center.x,
                                                ballRadius,
                                                planeAnchor.center.z + planeAnchor.extent.z / 2)
        wallPositiveZNode.geometry = wallPositiveZ
        wallPositiveZNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallPositiveZ, options: nil))
        wallPositiveZNode.physicsBody?.categoryBitMask = 2
        wallPositiveZNode.physicsBody?.contactTestBitMask = 1
        wallPositiveZNode.name = "+Z wall"
        
        node.addChildNode(wallPositiveZNode)
        
        let wallNegtiveX = SCNPlane(width: CGFloat(planeAnchor.extent.z), height: CGFloat(ballRadius * 2))
        let wallNegativeXMaterial = SCNMaterial()
        wallNegativeXMaterial.diffuse.contents = UIColor.blue
        wallNegtiveX.materials = [wallNegativeXMaterial]
        
        let wallNegativeXNode = SCNNode()
        wallNegativeXNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 0, 1, 0)
        wallNegativeXNode.position = SCNVector3(planeAnchor.center.x - planeAnchor.extent.x / 2,
                                                ballRadius,
                                                planeAnchor.center.z)
        
        wallNegativeXNode.geometry = wallNegtiveX
        wallNegativeXNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallNegtiveX, options: nil))
        wallNegativeXNode.physicsBody?.categoryBitMask = 2
        wallNegativeXNode.physicsBody?.contactTestBitMask = 1
        wallNegativeXNode.name = "-X wall"
        
        node.addChildNode(wallNegativeXNode)
        
        let wallPositiveX = SCNPlane(width: CGFloat(planeAnchor.extent.z), height: CGFloat(ballRadius * 2))
        let wallPositiveXMaterial = SCNMaterial()
        wallPositiveXMaterial.diffuse.contents = UIColor.blue
        wallPositiveX.materials = [wallPositiveXMaterial]
        
        let wallPositiveXNode = SCNNode()
        wallPositiveXNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 0, 1, 0)
        wallPositiveXNode.position = SCNVector3(planeAnchor.center.x + planeAnchor.extent.x / 2,
                                                ballRadius,
                                                planeAnchor.center.z)
        wallPositiveXNode.geometry = wallPositiveX
        wallPositiveXNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallPositiveX, options: nil))
        wallPositiveXNode.physicsBody?.categoryBitMask = 2
        wallPositiveXNode.physicsBody?.contactTestBitMask = 1
        wallPositiveXNode.name = "+X wall"
        
        node.addChildNode(wallPositiveXNode)
    }
    
    private func setupMotherBall(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        let motherBall = SCNSphere(radius: CGFloat(ballRadius))
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIColor.red
        motherBall.materials = [ballMaterial]
        
        motherBallNode = BallNode()
        motherBallNode.position = SCNVector3(planeAnchor.center.x, ballRadius, planeAnchor.center.z)
        motherBallNode.geometry = motherBall
        motherBallNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: motherBall, options: nil))
        motherBallNode.physicsBody?.categoryBitMask = 1
        motherBallNode.physicsBody?.contactTestBitMask = 2
        motherBallNode.name = "mother"
        
        node.addChildNode(motherBallNode)
    }
    
    private func setupTargetBall(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        let targetBall = SCNSphere(radius: CGFloat(ballRadius))
        let targetBallMaterial = SCNMaterial()
        targetBallMaterial.diffuse.contents = UIColor.yellow
        targetBall.materials = [targetBallMaterial]
        
        targetBallNode = BallNode()
        targetBallNode.position = SCNVector3(planeAnchor.center.x + 0.2, ballRadius, planeAnchor.center.z)
        targetBallNode.geometry = targetBall
        targetBallNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: targetBall, options: nil))
        targetBallNode.physicsBody?.categoryBitMask = 1
        targetBallNode.physicsBody?.contactTestBitMask = 1
        targetBallNode.name = "target"
        
        node.addChildNode(targetBallNode)
    }
}

extension MainViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var motherBallNode: BallNode!
        var targetBallNode: BallNode?
        var wallNode: SCNNode!
        if contact.nodeA.name == "mother" {
            motherBallNode = (contact.nodeA as! BallNode)
            wallNode = contact.nodeB
            //targetBallNode = contact.nodeB
        }
        
        if contact.nodeB.name == "mother" {
            motherBallNode = (contact.nodeB as! BallNode)
            wallNode = contact.nodeA
            //targetBallNode = contact.nodeA
        }

        motherBallNode.removeAction(forKey: "Move")
        guard motherBallNode.ballSpeed > 0.01 else { return }
        motherBallNode.ballSpeed = motherBallNode.ballSpeed / 2
        
        let normal = contact.contactNormal.xzPlane
        
        let normalComponent = motherBallNode.ballDirection.normalComponent(wrt: normal)
        let tangentCompoent = motherBallNode.ballDirection.tangentComponent(wrt: normal)
        let reflectedBallDirection = SCNVector3(tangentCompoent.x - normalComponent.x,
                                                0,
                                                tangentCompoent.z - normalComponent.z)
        
        motherBallNode.runAction(SCNAction.moveBy(x: CGFloat(reflectedBallDirection.x * motherBallNode.ballSpeed * 3),
                                                  y: 0,
                                                  z: CGFloat(reflectedBallDirection.x * motherBallNode.ballSpeed * 3),
                                                  duration: 3), forKey: "Move")
        
        
//        let dist: Float = 0.05
//        motherBallNode.runAction(SCNAction.moveBy(x: CGFloat(normal.x * dist),
//                                                  y: 0,
//                                                  z: CGFloat(normal.z * dist),
//                                                  duration: 2))
//
//        targetBallNode.runAction(SCNAction.moveBy(x: CGFloat(-normal.x * dist),
//                                                  y: 0,
//                                                  z: CGFloat(-normal.z * dist),
//                                                  duration: 2))
    }
}