//
//  KaleidoscopeViewController.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/4/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import Darwin
import GLKit
import OpenGLES
import AVFoundation
import CoreVideo
import CoreMedia

enum MirrorTextureSoure {
    case Image, Color, Video
}

class KaleidoscopeViewController: UIViewController, SCNSceneRendererDelegate, SCNProgramDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var settingsOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var settingsContainerView: UIView!
    
    var textureSource = MirrorTextureSoure.Video
    var hasMirror = false
    var videoCapture = VideoCaptureBuffer()
    
    private weak var settingsViewController:KaleidoscopeSettingsViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // create a new scene
        let scene = SCNScene()
        
        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()

        // delegate to self
        scnView.delegate = self
        
        scene.rootNode.runAction(SCNAction.customActionWithDuration(5, actionBlock:{
            (triNode:SCNNode!, elapsedTime:CGFloat) -> Void in
        }))
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        
        //camera.usesOrthographicProjection = true
        
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode;
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light.type = SCNLightTypeAmbient
        ambientLightNode.light.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        let gestureRecognizers = NSMutableArray()
        gestureRecognizers.addObject(tapGesture)
        gestureRecognizers.addObjectsFromArray(scnView.gestureRecognizers)
        scnView.gestureRecognizers = gestureRecognizers
        
        for controller in self.childViewControllers {
            if controller.isKindOfClass(KaleidoscopeSettingsViewController) {
                let settingsViewController = controller as KaleidoscopeSettingsViewController
                settingsViewController.kaleidoscopeViewController = self
                self.settingsViewController = settingsViewController
            }
        }
    }
    
    func createSphereNode(color:UIColor) -> SCNNode {
        
        let sphere = SCNSphere()
        var material = SCNMaterial()
        material.diffuse.contents  = color
        sphere.materials = [material];
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        sphereNode.scale = SCNVector3Make(0.25, 0.25, 0.25)
        return sphereNode
    }
    
    func createCorners() {
        
        var scnView = self.view as SCNView
        
        let extents = scnView.getExtents()
        let minEx = extents.min
        let maxEx = extents.max
        
        let scene = scnView.scene
        
        var sphereCenterNode = createSphereNode(UIColor.redColor())
        sphereCenterNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        scene.rootNode.addChildNode(sphereCenterNode)
        
        var sphereLLNode = createSphereNode(UIColor.blueColor())
        sphereLLNode.position = SCNVector3Make(minEx.x, minEx.y, 0.0)
        scene.rootNode.addChildNode(sphereLLNode)
        
        var sphereURNode = createSphereNode(UIColor.greenColor())
        sphereURNode.position = SCNVector3Make(maxEx.x, maxEx.y, 0.0)
        scene.rootNode.addChildNode(sphereURNode)
    }
    
    private var _videoActionRate = FrequencyCounter();
    func createMirror() {
        
        if !hasMirror {
            //createCorners()
            
            let scnView = self.view as SCNView
            let scene = scnView.scene
            
            let triNode = SCNNode()
            
            var geometry = Geometry.createKaleidoscopeMirrorWithIsoscelesTriangles(scnView)
            triNode.geometry = geometry
            triNode.position = SCNVector3(x: 0, y: 0, z: 0)
            
            if(self.textureSource == .Video) {
                geometry.materials = [self.createVideoTextureMaterial()]
            }
            else if(self.textureSource == .Color) {
                var material = SCNMaterial()
                material.diffuse.contents = UIColor.randomColor()
                geometry.materials = [material]
            }
            else if(self.textureSource == .Image) {
                var me = UIImage(named: "me2")
                var material = SCNMaterial()
                material.diffuse.contents = me
                geometry.materials = [material]
            }
            
            //triNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            
            triNode.name = "mirrors"

            var videoAction = SCNAction.customActionWithDuration(10000000000, actionBlock:{
                (triNode:SCNNode!, elapsedTime:CGFloat) -> Void in
                //NSLog("Running action")
                
                if self._videoActionRate.count == 0 {
                    self._videoActionRate.start()
                }
                self._videoActionRate.increment()
                if self._videoActionRate.count % 30 == 0 {
                    //NSLog("Video Action Rate: \(self._videoActionRate.frequency)/sec")
                }
                
                self.videoCapture.processNextVideoTexture()
            })
            
            var swellAction = SCNAction.repeatActionForever(SCNAction.sequence(
                [
                    SCNAction.scaleTo(1.01, duration: 1),
                    SCNAction.scaleTo(1.0, duration: 1),
                ]))

            var actions = SCNAction.group([videoAction])
            
            triNode.runAction(actions)
         
            scene.rootNode.addChildNode(triNode)
            
            hasMirror = true
            
            if(self.textureSource == .Video) {
                self.videoCapture.initVideoCapture(scnView.eaglContext)
            }
        }
    }
    
    func createVideoTextureMaterial() -> SCNMaterial {
        
        var material = SCNMaterial()
        var program = SCNProgram()
        var vertexShaderURL = NSBundle.mainBundle().URLForResource("Shader", withExtension: "vsh")
        var fragmentShaderURL = NSBundle.mainBundle().URLForResource("Shader", withExtension: "fsh")
        var vertexShaderSource = NSString(contentsOfURL: vertexShaderURL, encoding: NSUTF8StringEncoding, error: nil)
        var fragmentShaderSource = NSString(contentsOfURL: fragmentShaderURL, encoding: NSUTF8StringEncoding, error: nil)
        
        program.vertexShader = vertexShaderSource
        program.fragmentShader = fragmentShaderSource
        
        // Bind the position of the geometry and the model view projection
        // you would do the same for other geometry properties like normals
        // and other geometry properties/transforms.
        //
        // The attributes and uniforms in the shaders are defined as:
        // attribute vec4 position;
        // attribute vec2 textureCoordinate;
        // uniform mat4 modelViewProjection;
        
        program.setSemantic(SCNGeometrySourceSemanticVertex, forSymbol: "position", options: nil)
        program.setSemantic(SCNGeometrySourceSemanticTexcoord, forSymbol: "textureCoordinate", options: nil)
        program.setSemantic(SCNModelViewProjectionTransform, forSymbol: "modelViewProjection", options: nil)
        
        program.delegate = self
        
        material.program = program
        material.doubleSided = true
        material.handleBindingOfSymbol("SamplerY", usingBlock: {
            (programId:UInt32, location:UInt32, node:SCNNode!, renderer:SCNRenderer!) -> Void in
                //NSLog("handleBindingOfSymbol: SamplerY")
                glUniform1i(GLint(location), 0)
            }
        )
        
        material.handleBindingOfSymbol("SamplerUV", usingBlock: {
            (programId:UInt32, location:UInt32, node:SCNNode!, renderer:SCNRenderer!) -> Void in
                //NSLog("handleBindingOfSymbol: SamplerUY")
               glUniform1i(GLint(location), 1)
            }
        )
        
        return material
    }
    
    // SCNProgramDelegate
    func program(program: SCNProgram!, handleError error: NSError!) {
        NSLog("%@", error)
    }
    
    // SCNSceneRendererDelegate
    private var _renderCount = 0
    func renderer(aRenderer: SCNSceneRenderer!, didRenderScene scene: SCNScene!, atTime time: NSTimeInterval) {
        if _renderCount++ > 0 {
            self.createMirror()
        }
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {

        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        // check what nodes are tapped
        let viewPoint = gestureRecognize.locationInView(scnView)
        
        var camera = scnView.pointOfView.camera
        
        let projectedOrigin = scnView.projectPoint(SCNVector3Zero)
        let vpWithZ = SCNVector3Make(Float(viewPoint.x), Float(viewPoint.y), projectedOrigin.z)
        var scenePoint = scnView.unprojectPoint(vpWithZ)
        println("tapPoint: (\(viewPoint.x), \(viewPoint.y)) scenePoint: (\(scenePoint.x), \(scenePoint.y), \(scenePoint.z))")
    }
    
    //
    // Settings
    //
    func startBreathing(depth:CGFloat, duration:NSTimeInterval) {
        
        self.stopBreathing()
        
        let scnView = self.view as SCNView
        var mirrorNode = scnView.scene.rootNode.childNodeWithName("mirrors", recursively: false)
        
        var breatheAction = SCNAction.repeatActionForever(SCNAction.sequence(
            [
                SCNAction.scaleTo(depth, duration: duration/2.0),
                SCNAction.scaleTo(1.0, duration: duration/2.0),
            ]))

        mirrorNode.runAction(breatheAction, forKey: "breatheAction")
    }

    func stopBreathing() {
        let scnView = self.view as SCNView
        var mirrorNode = scnView.scene.rootNode.childNodeWithName("mirrors", recursively: false)
        mirrorNode.removeActionForKey("breatheAction")
    }

    var isUsingFrontFacingCamera:Bool {
        get {
            return self.videoCapture.isUsingFrontFacingCamera
        }
        
        set {
            if newValue != self.videoCapture.isUsingFrontFacingCamera {
                self.videoCapture.switchCameras()
            }
        }
    }
    
    var maxZoom:CGFloat {
        get {
            return self.videoCapture.maxZoom
        }
    }
    
    var zoom:CGFloat {
        get {
            return self.videoCapture.zoom
        }
        
        set {
            self.videoCapture.zoom = newValue
        }
    }
    
    var isSettingsOpen = false
    
    @IBAction func settingsButtonFired(sender: UIButton) {
        
        self.view.layoutIfNeeded()
        var offset = (self.isSettingsOpen ? -(self.settingsContainerView.frame.size.width + 20) : -20)
        
        if !self.isSettingsOpen {
            self.settingsViewController!.settingsWillOpen()
        }
        
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: ({
            self.settingsOffsetConstraint.constant = offset
            self.view.layoutIfNeeded()
        }), completion: {
            (finished:Bool) -> Void in
            self.isSettingsOpen = !self.isSettingsOpen
            let scnView = self.view as SCNView
            scnView.allowsCameraControl = !self.isSettingsOpen
            
            if !self.isSettingsOpen {
                self.settingsViewController!.settingsDidClose()
            }
        })
    }
    
    //
    // UIViewControlle overrides
    //
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
        } else {
            return Int(UIInterfaceOrientationMask.All.toRaw())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
