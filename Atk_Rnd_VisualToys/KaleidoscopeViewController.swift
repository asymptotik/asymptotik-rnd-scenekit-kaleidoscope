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
    
    var tmpTexture:TmpTexture?
    
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

        // Anti alias
        //scnView.antialiasingMode = SCNAntialiasingMode.Multisampling4X
        
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
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        let gestureRecognizers = NSMutableArray()
        gestureRecognizers.addObject(tapGesture)
        
        if let recognizers = scnView.gestureRecognizers {
            gestureRecognizers.addObjectsFromArray(recognizers)
        }
        
        scnView.gestureRecognizers = gestureRecognizers
        
        for controller in self.childViewControllers {
            if controller.isKindOfClass(KaleidoscopeSettingsViewController) {
                let settingsViewController = controller as KaleidoscopeSettingsViewController
                settingsViewController.kaleidoscopeViewController = self
                self.settingsViewController = settingsViewController
            }
        }

        self.videoRecordingTmpUrl = NSURL(fileURLWithPath: (NSTemporaryDirectory().stringByAppendingPathComponent("video.mov")));
        self.screenTexture = ScreenTextureQuad()
        self.screenTexture!.initialize()
        
        self.tmpTexture = TmpTexture()
        
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
        
        let scene = scnView.scene!
        
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
            
            let scnView:SCNView = self.view as SCNView
            let scene = scnView.scene!
            
            let triNode = SCNNode()
            
            var geometry = Geometry.createKaleidoscopeMirrorWithEquilateralTriangles(scnView)
            //var geometry = Geometry.createSquare(scnView)
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
        var vertexShaderSource = NSString(contentsOfURL: vertexShaderURL!, encoding: NSUTF8StringEncoding, error: nil)
        var fragmentShaderSource = NSString(contentsOfURL: fragmentShaderURL!, encoding: NSUTF8StringEncoding, error: nil)
        
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
    func program(program: SCNProgram!, handleError error: NSError!) {
        NSLog("%@", error)
    }
    
    func renderer(aRenderer: SCNSceneRenderer!, willRenderScene scene: SCNScene!, atTime time: NSTimeInterval) {

        if _renderCount >= 1 && self.recordingStatus == RecordingStatus.Recording {
            self.videoRecorder!.bindRenderTextureFramebuffer()
        }
        
        //self.videoRecorder!.bindRenderTextureFramebuffer()
    }
    
    // SCNSceneRendererDelegate
    private var _renderCount = 0
    func renderer(aRenderer: SCNSceneRenderer!, didRenderScene scene: SCNScene!, atTime time: NSTimeInterval) {
        
        if _renderCount == 1 {
            self.createMirror()
            glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &self.defaultFBO)
            NSLog("Default framebuffer: %d", self.defaultFBO)
        }
        
        if _renderCount >= 1 {
            
            if self.snapshotRequested {
                self.takeShot()
                self.snapshotRequested = false
            }
            
            if self.recordingStatus == RecordingStatus.Recording {
                var scnView = self.view as SCNView

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
            
            //self.screenTexture!.draw(self.tmpTexture!.spriteTexture.target, name: self.tmpTexture!.spriteTexture.name)
            
        }

        _renderCount++;
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
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {

        // retrieve the SCNView
        let scnView:SCNView = self.view as SCNView
        
        // check what nodes are tapped
        let viewPoint = gestureRecognize.locationInView(scnView)
        
        var camera = scnView.pointOfView!.camera
        
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
        
        let scnView:SCNView = self.view as SCNView
        var mirrorNode = scnView.scene?.rootNode.childNodeWithName("mirrors", recursively: false)
        
        if let mirrorNode = mirrorNode {
            var breatheAction = SCNAction.repeatActionForever(SCNAction.sequence(
                [
                    SCNAction.scaleTo(depth, duration: duration/2.0),
                    SCNAction.scaleTo(1.0, duration: duration/2.0),
                ]))

            mirrorNode.runAction(breatheAction, forKey: "breatheAction")
        }
    }

    func stopBreathing() {
        let scnView = self.view as SCNView
        var mirrorNode = scnView.scene?.rootNode.childNodeWithName("mirrors", recursively: false)
        
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
        var offset = (self.isSettingsOpen ? -(self.settingsWidthConstraint.constant) : 0)
        
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
            let scnView = self.view as SCNView
            
            var width:GLsizei = GLsizei(scnView.bounds.size.width * UIScreen.mainScreen().scale)
            var height:GLsizei = GLsizei(scnView.bounds.size.height * UIScreen.mainScreen().scale)
            
            self.videoRecorder = FrameBufferVideoRecorder(movieUrl: self.videoRecordingTmpUrl,
                width: width,
                height: height)
            
            self.videoRecorder!.initVideoRecorder(scnView.eaglContext)
            self.videoRecorder!.generateFramebuffer(scnView.eaglContext)
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
                
                var fileManager: NSFileManager = NSFileManager.defaultManager()
                if fileManager.fileExistsAtPath(self.videoRecordingTmpUrl.path!) {
                    UISaveVideoAtPathToSavedPhotosAlbum(self.videoRecordingTmpUrl.path, self, "video:didFinishSavingWithError:contextInfo:", nil)
                }
                else {
                    NSLog("File does not exist: " + self.videoRecordingTmpUrl.path!);
                }
            }
        })
    }
    
    func video(videoPath:NSString, didFinishSavingWithError error:NSErrorPointer, contextInfo:UnsafeMutablePointer<Void>) {
        NSLog("Finished saving video")
        self.deleteFile(self.videoRecordingTmpUrl)
    }
    
    func deleteFile(fileUrl:NSURL) {
        var fileManager: NSFileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(fileUrl.path!) {
            var error:NSError? = nil;
            fileManager.removeItemAtURL(fileUrl, error: &error)
            if(error != nil) {
                NSLog("Error deleing file: %@ Error: %@", fileUrl, error!)
            }
        }
    }
    
    func takeShot() {
        var image = self.imageFromSceneKitView(self.view as SCNView)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func imageFromSceneKitView(sceneKitView:SCNView) -> UIImage {
        var w:UInt = UInt(sceneKitView.bounds.size.width * UIScreen.mainScreen().scale)
        var h:UInt = UInt(sceneKitView.bounds.size.height * UIScreen.mainScreen().scale)
        
        let myDataLength:UInt = w * h * UInt(4)
        var buffer = UnsafeMutablePointer<CGFloat>(calloc(myDataLength, UInt(sizeof(CUnsignedChar))))
        
        glReadPixels(0, 0, GLint(w), GLint(h), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), buffer)
        
        var provider = CGDataProviderCreateWithData(nil, buffer, UInt(myDataLength), nil)
        
        var bitsPerComponent:UInt = 8
        var bitsPerPixel:UInt = 32
        var bytesPerRow:UInt = UInt(4) * UInt(w)
        var colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo.ByteOrderDefault
        var renderingIntent = kCGRenderingIntentDefault
        
        // make the cgimage
        var cgImage = CGImageCreate(UInt(w), UInt(h), bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, nil, false, renderingIntent)
        return UIImage(CGImage: cgImage)
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
