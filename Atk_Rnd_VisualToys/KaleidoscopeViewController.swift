//
//  KaleidoscopeViewController.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/4/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
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

enum RecordingStatus {
    case Stopped, Finishing, FinishRequested, Recording
}

class KaleidoscopeViewController: UIViewController, SCNSceneRendererDelegate, SCNProgramDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var settingsOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var settingsContainerView: UIView!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var imageRecording: UIImageView!
    
    var textureSource = MirrorTextureSoure.Video
    var hasMirror = false
    var videoCapture = VideoCaptureBuffer()
    
    var videoRecorder:FrameBufferVideoRecorder?
    var videoRecordingTmpUrl: NSURL!;
    var recordingStatus = RecordingStatus.Stopped;
    var defaultFBO:GLint = 0

    var snapshotRequested = false;
    
    private weak var settingsViewController:KaleidoscopeSettingsViewController? = nil
    
    var textureRotation:GLfloat = 0.0
    var textureRotationSpeed:GLfloat = 0.1
    var rotateTexture = false
    
    var screenTexture:ScreenTextureQuad?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // create a new scene
        let scene = SCNScene()
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()

        // Anti alias
        scnView.antialiasingMode = SCNAntialiasingMode.Multisampling4X
        
        // delegate to self
        scnView.delegate = self

        scene.rootNode.runAction(SCNAction.customActionWithDuration(5, actionBlock:{
            (triNode:SCNNode, elapsedTime:CGFloat) -> Void in
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
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
        
        // add a tap gesture recognizer
        //let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        //let pinchGesture = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
        //let panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        //var gestureRecognizers:[AnyObject] = [tapGesture, pinchGesture, panGesture]
        
        //if let recognizers = scnView.gestureRecognizers {
        //    gestureRecognizers += recognizers
        //}
        
        //scnView.gestureRecognizers = gestureRecognizers
        
        for controller in self.childViewControllers {
            if controller.isKindOfClass(KaleidoscopeSettingsViewController) {
                let settingsViewController = controller as! KaleidoscopeSettingsViewController
                settingsViewController.kaleidoscopeViewController = self
                self.settingsViewController = settingsViewController
            }
        }

        self.videoRecordingTmpUrl = NSURL(fileURLWithPath: (NSTemporaryDirectory().stringByAppendingPathComponent("video.mov")));
        self.screenTexture = ScreenTextureQuad()
        self.screenTexture!.initialize()
        
        OpenGlUtils.checkError("init")
    }
    
    override func viewWillLayoutSubviews() {
        
        let viewFrame = self.view.frame
        
        if(self.settingsViewController?.view.frame.width > viewFrame.width) {
            var frame = self.settingsViewController!.view.frame
            frame.size.width = viewFrame.width
            self.settingsOffsetConstraint.constant = -frame.size.width
            self.settingsWidthConstraint.constant = frame.size.width
        }
    }
    
    func createSphereNode(color:UIColor) -> SCNNode {
        
        let sphere = SCNSphere()
        let material = SCNMaterial()
        material.diffuse.contents  = color
        sphere.materials = [material];
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        sphereNode.scale = SCNVector3Make(0.25, 0.25, 0.25)
        return sphereNode
    }
    
    func createCorners() {
        
        let scnView = self.view as! SCNView
        
        let extents = scnView.getExtents()
        let minEx = extents.min
        let maxEx = extents.max
        
        let scene = scnView.scene!
        
        let sphereCenterNode = createSphereNode(UIColor.redColor())
        sphereCenterNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        scene.rootNode.addChildNode(sphereCenterNode)
        
        let sphereLLNode = createSphereNode(UIColor.blueColor())
        sphereLLNode.position = SCNVector3Make(minEx.x, minEx.y, 0.0)
        scene.rootNode.addChildNode(sphereLLNode)
        
        let sphereURNode = createSphereNode(UIColor.greenColor())
        sphereURNode.position = SCNVector3Make(maxEx.x, maxEx.y, 0.0)
        scene.rootNode.addChildNode(sphereURNode)
    }
    
    private var _videoActionRate = FrequencyCounter();
    func createMirror() -> Bool {
        
        var ret:Bool = false
        
        if !hasMirror {
            //createCorners()
            
            let scnView:SCNView = self.view as! SCNView
            let scene = scnView.scene!
            
            let triNode = SCNNode()
            
            //let geometry = Geometry.createKaleidoscopeMirrorWithEquilateralTriangles(scnView)
            let geometry = Geometry.createKaleidoscopeMirrorWithIsoscelesTriangles(scnView)
            //var geometry = Geometry.createSquare(scnView)
            triNode.geometry = geometry
            triNode.position = SCNVector3(x: 0, y: 0, z: 0)
            
            if(self.textureSource == .Video) {
                geometry.materials = [self.createVideoTextureMaterial()]
            }
            else if(self.textureSource == .Color) {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.randomColor()
                geometry.materials = [material]
            }
            else if(self.textureSource == .Image) {
                let me = UIImage(named: "me2")
                let material = SCNMaterial()
                material.diffuse.contents = me
                geometry.materials = [material]
            }
            
            //triNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            
            triNode.name = "mirrors"

            let videoAction = SCNAction.customActionWithDuration(10000000000, actionBlock:{
                (triNode:SCNNode, elapsedTime:CGFloat) -> Void in
                //NSLog("Running action: processNextVideoTexture")
                
                if self._videoActionRate.count == 0 {
                    self._videoActionRate.start()
                }
                self._videoActionRate.increment()
                if self._videoActionRate.count % 30 == 0 {
                    //NSLog("Video Action Rate: \(self._videoActionRate.frequency)/sec")
                }
                
                self.videoCapture.processNextVideoTexture()
            })
            
            /*
            var swellAction = SCNAction.repeatActionForever(SCNAction.sequence(
                [
                    SCNAction.scaleTo(1.01, duration: 1),
                    SCNAction.scaleTo(1.0, duration: 1),
                ]))
            */
            
            let actions = SCNAction.group([videoAction])
            
            triNode.runAction(actions)
         
            scene.rootNode.addChildNode(triNode)
            
            hasMirror = true
            ret = true
        }
        
        return ret;
    }
    
    func createVideoTextureMaterial() -> SCNMaterial {
        
        let material = SCNMaterial()
        let program = SCNProgram()
        let vertexShaderURL = NSBundle.mainBundle().URLForResource("Shader", withExtension: "vsh")
        let fragmentShaderURL = NSBundle.mainBundle().URLForResource("Shader", withExtension: "fsh")
        var vertexShaderSource: NSString?
        do {
            vertexShaderSource = try NSString(contentsOfURL: vertexShaderURL!, encoding: NSUTF8StringEncoding)
        } catch _ {
            vertexShaderSource = nil
        }
        var fragmentShaderSource: NSString?
        do {
            fragmentShaderSource = try NSString(contentsOfURL: fragmentShaderURL!, encoding: NSUTF8StringEncoding)
        } catch _ {
            fragmentShaderSource = nil
        }
        
        program.vertexShader = vertexShaderSource as? String
        program.fragmentShader = fragmentShaderSource as? String
        
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
                glUniform1i(GLint(location), 0)
            }
        )
        
        material.handleBindingOfSymbol("SamplerUV", usingBlock: {
            (programId:UInt32, location:UInt32, node:SCNNode!, renderer:SCNRenderer!) -> Void in
               glUniform1i(GLint(location), 1)
            }
        )
        
        material.handleBindingOfSymbol("TexRotation", usingBlock: {
            (programId:UInt32, location:UInt32, node:SCNNode!, renderer:SCNRenderer!) -> Void in
            glUniform1f(GLint(location), self.textureRotation)
            }
        )
        
        return material
    }

    // SCNProgramDelegate
    func program(program: SCNProgram, handleError error: NSError) {
        NSLog("%@", error)
    }
    
    func renderer(aRenderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {

        if _renderCount >= 1 && self.recordingStatus == RecordingStatus.Recording {
            self.videoRecorder!.bindRenderTextureFramebuffer()
        }
        
        //self.videoRecorder!.bindRenderTextureFramebuffer()
    }
    
    // SCNSceneRendererDelegate
    private var _renderCount = 0
    func renderer(aRenderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        
        if _renderCount == 1 {
            self.createMirror()
            
            if(self.textureSource == .Video) {
                let scnView:SCNView = self.view as! SCNView
                self.videoCapture.initVideoCapture(scnView.eaglContext!)
            }
            
            glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &self.defaultFBO)
            NSLog("Default framebuffer: %d", self.defaultFBO)
        }
        
        if _renderCount >= 1 {
            
            if self.snapshotRequested {
                self.takeShot()
                self.snapshotRequested = false
            }
            
            if self.recordingStatus == RecordingStatus.Recording {
               // var scnView = self.view as! SCNView

                glFlush()
                glFinish()
                self.videoRecorder!.grabFrameFromRenderTexture(time)
                
                // Works here
                glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(self.defaultFBO))
                self.screenTexture!.draw(self.videoRecorder!.target, name: self.videoRecorder!.name)
                
            } else if self.recordingStatus == RecordingStatus.FinishRequested {
                self.recordingStatus = RecordingStatus.Finishing
                Async.background({ () -> Void in
                    self.finishRecording()
                })
            }
            
            //glFinish()
            //glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(self.defaultFBO))
            //self.screenTexture!.draw(self.videoRecorder!.target, name: self.videoRecorder!.name)

        }

        _renderCount++;
        
        /*
        let scnView:SCNView = self.view as SCNView
        var camera = scnView.pointOfView!.camera
        
        slideVelocity = Rotation.rotateCamera(scnView.pointOfView!, velocity: slideVelocity)
        */
    }
    
    private var _lastRenderTime: NSTimeInterval = 0.0
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        if(_lastRenderTime > 0.0) {
            if self.rotateTexture {
                self.textureRotation += self.textureRotationSpeed * Float(time - _lastRenderTime)
            }
            else {
                self.textureRotation = 0.0
            }
        }
        
        _lastRenderTime = time;
    }

    func handleTap(recognizer: UIGestureRecognizer) {
        
        // retrieve the SCNView
        let scnView:SCNView = self.view as! SCNView
        
        // check what nodes are tapped
        let viewPoint = recognizer.locationInView(scnView)
        
        for var node:SCNNode? = scnView.pointOfView; node != nil; node = node?.parentNode {
            NSLog("Node: " + node!.description)
            NSLog("Node pivot: " + node!.pivot.description)
            NSLog("Node constraints: \(node!.constraints?.description)")
        }
        
        let projectedOrigin = scnView.projectPoint(SCNVector3Zero)
        let vpWithZ = SCNVector3Make(Float(viewPoint.x), Float(viewPoint.y), projectedOrigin.z)
        let scenePoint = scnView.unprojectPoint(vpWithZ)
        print("tapPoint: (\(viewPoint.x), \(viewPoint.y)) scenePoint: (\(scenePoint.x), \(scenePoint.y), \(scenePoint.z))")
    }
    
    private var currentScale:Float = 1.0
    private var lastScale:CGFloat = 1.0
    func handlePinch(recognizer: UIPinchGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizerState.Began {
            lastScale = recognizer.scale
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            
            let scnView:SCNView = self.view as! SCNView
            let cameraNode = scnView.pointOfView!
            let position = cameraNode.position
            
            var scale:Float = 1.0 - Float(recognizer.scale - lastScale)
            scale = min(scale, 40.0 / currentScale)
            scale = max(scale, 0.1 / currentScale)
            
            currentScale = scale
            lastScale = recognizer.scale
            
            let z = max(0.02, position.z * scale)
            
            cameraNode.position.z = z
        }
    }
    
    var slideVelocity = CGPointMake(0.0, 0.0)
    var cameraRot = CGPointMake(0.0, 0.0)
    var panPoint = CGPointMake(0.0, 0.0)
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizerState.Began {
            panPoint = recognizer.locationInView(self.view)
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            let pt = recognizer.locationInView(self.view)
            cameraRot.x += (pt.x - panPoint.x) * CGFloat(M_PI / 180.0)
            cameraRot.y += (pt.y - panPoint.y) * CGFloat(M_PI / 180.0)
            panPoint = pt
        }
        
        let x = Float(15 * sin(cameraRot.x))
        let z = Float(15 * cos(cameraRot.x))
        
        slideVelocity = recognizer.velocityInView(self.view)
        
        let scnView:SCNView = self.view as! SCNView
        let cameraNode = scnView.pointOfView!
        cameraNode.position = SCNVector3Make(x, 0, z)
        
        var vect = SCNVector3Make(0, 0, 0) - cameraNode.position
        vect.normalize()
        let at1 = atan2(vect.x, vect.z)
        let at2 = Float(atan2(0.0, -1.0))
        let angle = at1 - at2
        NSLog("Angle: %f", angle)
        cameraNode.rotation = SCNVector4Make(0, 1, 0, angle)
    }
    
    //
    // Settings
    //
    func startBreathing(depth:CGFloat, duration:NSTimeInterval) {
        
        self.stopBreathing()
        
        let scnView:SCNView = self.view as! SCNView
        let mirrorNode = scnView.scene?.rootNode.childNodeWithName("mirrors", recursively: false)
        
        if let mirrorNode = mirrorNode {
            let breatheAction = SCNAction.repeatActionForever(SCNAction.sequence(
                [
                    SCNAction.scaleTo(depth, duration: duration/2.0),
                    SCNAction.scaleTo(1.0, duration: duration/2.0),
                ]))

            mirrorNode.runAction(breatheAction, forKey: "breatheAction")
        }
    }

    func stopBreathing() {
        let scnView = self.view as! SCNView
        let mirrorNode = scnView.scene?.rootNode.childNodeWithName("mirrors", recursively: false)
        
        if let mirrorNode = mirrorNode {
            mirrorNode.removeActionForKey("breatheAction")
        }
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

        if !self.isSettingsOpen {
            
            self.settingsViewController!.settingsWillOpen()
        }
        
        self.view.layoutIfNeeded()
        let offset = (self.isSettingsOpen ? -(self.settingsWidthConstraint.constant) : 0)
        
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: ({
            self.settingsOffsetConstraint.constant = offset
            self.view.layoutIfNeeded()
        }), completion: {
            (finished:Bool) -> Void in
            self.isSettingsOpen = !self.isSettingsOpen
            let scnView = self.view as! SCNView
            scnView.allowsCameraControl = !self.isSettingsOpen
            
            if !self.isSettingsOpen {
                self.settingsViewController!.settingsDidClose()
            }
        })
    }

    @IBAction func videoButtonFired(sender: UIButton) {
        
        if self.recordingStatus == RecordingStatus.Stopped  {
            self.setupVideoRecorderRecording()
            self.recordingStatus = RecordingStatus.Recording;
            self.imageRecording.hidden = false
        }
        else if self.recordingStatus == RecordingStatus.Recording {
            self.imageRecording.hidden = true
            self.stopRecording()
        }
    }
    
    private func setupVideoRecorderRecording() {
        self.deleteFile(self.videoRecordingTmpUrl)
        
        if(self.videoRecorder == nil) {
            // retrieve the SCNView
            let scnView = self.view as! SCNView
            
            let width:GLsizei = GLsizei(scnView.bounds.size.width * UIScreen.mainScreen().scale)
            let height:GLsizei = GLsizei(scnView.bounds.size.height * UIScreen.mainScreen().scale)
            
            self.videoRecorder = FrameBufferVideoRecorder(movieUrl: self.videoRecordingTmpUrl,
                width: width,
                height: height)
            
            self.videoRecorder!.initVideoRecorder(scnView.eaglContext!)
            self.videoRecorder!.generateFramebuffer(scnView.eaglContext!)
        }
    }
    
    private func stopRecording() {
        if self.recordingStatus == RecordingStatus.Recording {
            self.recordingStatus = RecordingStatus.FinishRequested;
        }
    }
    
    private func finishRecording() {
        
        self.videoRecorder?.finish({ (status:FrameBufferVideoRecorderStatus) -> Void in
            
            NSLog("Video recorder finished with status: " + status.description);
            
            if(status == FrameBufferVideoRecorderStatus.Completed) {
                
                let fileManager: NSFileManager = NSFileManager.defaultManager()
                if fileManager.fileExistsAtPath(self.videoRecordingTmpUrl.path!) {
                    UISaveVideoAtPathToSavedPhotosAlbum(self.videoRecordingTmpUrl.path!, self, "video:didFinishSavingWithError:contextInfo:", nil)
                }
                else {
                    NSLog("File does not exist: " + self.videoRecordingTmpUrl.path!);
                }
            }
        })
    }
    
    func video(videoPath:NSString, didFinishSavingWithError error:NSErrorPointer, contextInfo:UnsafeMutablePointer<Void>) {
        NSLog("Finished saving video")
        self.videoRecorder = nil;
        self.recordingStatus = RecordingStatus.Stopped
        self.deleteFile(self.videoRecordingTmpUrl)
    }
    
    func deleteFile(fileUrl:NSURL) {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(fileUrl.path!) {
            var error:NSError? = nil;
            do {
                try fileManager.removeItemAtURL(fileUrl)
            } catch let error1 as NSError {
                error = error1
            }
            if(error != nil) {
                NSLog("Error deleing file: %@ Error: %@", fileUrl, error!)
            }
        }
    }
    
    func takeShot() {
        let image = self.imageFromSceneKitView(self.view as! SCNView)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func imageFromSceneKitView(sceneKitView:SCNView) -> UIImage {
        let w:Int = Int(sceneKitView.bounds.size.width * UIScreen.mainScreen().scale)
        let h:Int = Int(sceneKitView.bounds.size.height * UIScreen.mainScreen().scale)
        
        let myDataLength:Int = w * h * Int(4)
        let buffer = UnsafeMutablePointer<CGFloat>(calloc(myDataLength, Int(sizeof(CUnsignedChar))))
        
        glReadPixels(0, 0, GLint(w), GLint(h), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), buffer)
        
        let provider = CGDataProviderCreateWithData(nil, buffer, Int(myDataLength), nil)
        
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        let bytesPerRow:Int = 4 * w
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.ByteOrderDefault
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        
        // make the cgimage
        let decode:UnsafePointer<CGFloat> = nil;
        let cgImage = CGImageCreate(w, h, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, decode, false, renderingIntent)
        return UIImage(CGImage: cgImage!)
    }

    //
    // UIViewControlle overrides
    //
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
