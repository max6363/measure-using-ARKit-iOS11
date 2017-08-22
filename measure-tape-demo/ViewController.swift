//
//  ViewController.swift
//  measure-tape-demo
//
//  Created by Minhaz on 19/08/17.
//  Copyright © 2017 aub. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    // planes
    var dictPlanes = [ARPlaneAnchor: Plane]()
    
    // distance label
    @IBOutlet weak var lblMeasurementDetails : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup scene
        self.setupScene()
    }

    // setup scene
    func setupScene()
    {
        // set delegate - ARSCNViewDelegate
        self.sceneView.delegate = self
        
        // showing statistics (fps, timing info)
        self.sceneView.showsStatistics = true
        self.sceneView.autoenablesDefaultLighting = true
        
        // debug points
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // create new scene
        let scene = SCNScene()
        self.sceneView.scene = scene
        
    }
    
    // start node
    var startNode: SCNNode?
    
    //MARK: - Action
    @IBAction func onAddButtonClick(_ sender: UIButton) {
        
        if let position = self.doHitTestOnExistingPlanes() {
            // add node at hit-position
            let node = self.nodeWithPosition(position)
            sceneView.scene.rootNode.addChildNode(node)
            
            // set start node
            startNode = node
        }
    }
    
    func doHitTestOnExistingPlanes() -> SCNVector3? {
        // hit-test of view's center with existing-planes
        let results = sceneView.hitTest(view.center,
                                        types: .existingPlaneUsingExtent)
        // check if result is available
        if let result = results.first {
            // get vector from transform
            let hitPos = self.positionFromTransform(result.worldTransform)
            return hitPos
        }
        return nil
    }
    
    // get position 'vector' from 'transform'
    func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x,
                              transform.columns.3.y,
                              transform.columns.3.z)
    }
    
    // add dot node with given position
    func nodeWithPosition(_ position: SCNVector3) -> SCNNode {
        // create sphere geometry with radius
        let sphere = SCNSphere(radius: 0.003)
        // set color
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 255/255.0,
                                                         green: 153/255.0,
                                                         blue: 83/255.0,
                                                         alpha: 1)
        // set lighting model
        sphere.firstMaterial?.lightingModel = .constant
        sphere.firstMaterial?.isDoubleSided = true
        // create node with 'sphere' geometry
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        return node
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // set up session
        self.setupARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // setup AR Session
    func setupARSession()
    {
        // create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        // set to detect horizontal planes
        configuration.planeDetection = .horizontal
        
        // run the configuration
        self.sceneView.session.run(configuration)
    }

    // MARK: - ARSCNViewDelegate
    
    // line-node
    var line_node: SCNNode?
    
    // renderer callback method
    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval) {

        DispatchQueue.main.async {
            // get current hit position
            // and check if start-node is available
            guard let currentPosition = self.doHitTestOnExistingPlanes(),
                let start = self.startNode else {
                return
            }
            
            // line-node
            self.line_node?.removeFromParentNode()
            self.line_node = self.getDrawnLineFrom(pos1: currentPosition,
                                                   toPos2: start.position)
            self.sceneView.scene.rootNode.addChildNode(self.line_node!)
            
            // distance-string
            let desc = self.getDistanceStringBeween(pos1: currentPosition,
                                                    pos2: start.position)
            DispatchQueue.main.async {
                self.lblMeasurementDetails.text = desc
            }
        }
    }
    
    // draw line-node between two vectors
    func getDrawnLineFrom(pos1: SCNVector3,
                          toPos2: SCNVector3) -> SCNNode {
        
        let line = lineFrom(vector: pos1, toVector: toPos2)
        let lineInBetween1 = SCNNode(geometry: line)
        return lineInBetween1
    }
    
    // get line geometry between two vectors
    func lineFrom(vector vector1: SCNVector3,
                  toVector vector2: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices,
                                         primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    /**
     Distance string
     */
    func getDistanceStringBeween(pos1: SCNVector3?,
                                 pos2: SCNVector3?) -> String {
        
        if pos1 == nil || pos2 == nil {
            return "0"
        }
        let d = self.distanceBetweenPoints(A: pos1!, B: pos2!)
        
        var result = ""
        
        let meter = stringValue(v: Float(d), unit: "meters")
        result.append(meter)
        result.append("\n")
        
        let f = self.foot_fromMeter(m: Float(d))
        let feet = stringValue(v: Float(f), unit: "feet")
        result.append(feet)
        result.append("\n")
        
        let inch = self.Inch_fromMeter(m: Float(d))
        let inches = stringValue(v: Float(inch), unit: "inch")
        result.append(inches)
        result.append("\n")
        
        let cm = self.CM_fromMeter(m: Float(d))
        let cms = stringValue(v: Float(cm), unit: "cm")
        result.append(cms)
        
        return result
    }
    
    /**
     Distance between 2 points
     */
    func distanceBetweenPoints(A: SCNVector3, B: SCNVector3) -> CGFloat {
        let l = sqrt(
            (A.x - B.x) * (A.x - B.x)
                +   (A.y - B.y) * (A.y - B.y)
                +   (A.z - B.z) * (A.z - B.z)
        )
        return CGFloat(l)
    }
    
    /**
     String with float value and unit
     */
    func stringValue(v: Float, unit: String) -> String {
        let s = String(format: "%.1f %@", v, unit)
        return s
    }
    
    /**
     Inch from meter
     */
    func Inch_fromMeter(m: Float) -> Float {
        let v = m * 39.3701
        return v
    }
    
    /**
     centimeter from meter
     */
    func CM_fromMeter(m: Float) -> Float {
        let v = m * 100.0
        return v
    }
    
    /**
     feet from meter
     */
    func foot_fromMeter(m: Float) -> Float {
        let v = m * 3.28084
        return v
    }
    
    /**
     Called when a new node has been mapped to the given anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("--> did add node")
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                // create plane with the "PlaneAnchor"
                let plane = Plane(anchor: planeAnchor)
                // add to the detected
                node.addChildNode(plane)
                // add to dictionary
                self.dictPlanes[planeAnchor] = plane
            }
        }
    }
    
    /**
     Called when a node will be updated with data from the given anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) { }
    
    /**
     Called when a node has been updated with data from the given anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // get plane with anchor
                let plane = self.dictPlanes[planeAnchor]
                // update
                plane?.updateWith(planeAnchor)
            }
        }
    }
    
    /**
     Called when a mapped node has been removed from the scene graph for the given anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            self.dictPlanes.removeValue(forKey: planeAnchor)
        }
    }
}
