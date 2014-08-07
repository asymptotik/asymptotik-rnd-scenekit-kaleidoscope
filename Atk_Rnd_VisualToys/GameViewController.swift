//
//  GameViewController.swift
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

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNProgramDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    var session: AVCaptureSession? = nil
    var positionVBO: GLuint = 0
    var texcoordVBO: GLuint = 0
    var indexVBO: GLuint = 0
    var textureWidth: size_t = 0
    var textureHeight: size_t = 0
    var lumaTexture: CVOpenGLESTexture? = nil
    var chromaTexture: CVOpenGLESTexture? = nil
    var videoTextureCache: CVOpenGLESTextureCacheRef? = nil
    
    var videoBufferingDispatchQueue = dispatch_queue_create("video displatch queue",  DISPATCH_QUEUE_CONCURRENT)
    var videoBufferQueue = CircularQueue<CMSampleBuffer>(size:3)
    
    var textureSource = MirrorTextureSoure.Video
    var hasMirror = false
    
    @IBOutlet weak var videoView: UIView!
    
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
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.whiteColor()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        
        camera.usesOrthographicProjection = true
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
    }
    
    func defineMirrorGrid() -> SCNGeometry {
        
        let extents = self.getExtents()
        let minEx = extents.min
        let maxEx = extents.max
        
        println("minEx: (\(minEx.x), \(minEx.y), \(minEx.z)) maxEx: (\(maxEx.x), \(maxEx.y), \(maxEx.z))")
        
        let r:Float = 1.0;
        let tri_scale:Float = 0.5; //(float)randInt(120, 400);
    
        var co:Float = Float(cos(M_PI/3.0) * Double(r)); //0.5
        var si:Float = Float(sin(M_PI/3.0) * Double(r)); //0.86
        
        let tri_width:Float = r * tri_scale
        let tri_height:Float = si * tri_scale
        
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let width:Float = maxEx.x - minEx.x
        let height:Float = maxEx.y - minEx.y
        
        let amtX:Float = ceil((((width * Float(2.0)) - Float(0.5)) / (Float(1.5) * tri_width)) + Float(0.5) )
        let w:Float = ((amtX * Float(1.5)) + Float(0.5)) * tri_width
        let xOffset:Float = -((w - width)/Float(2.0))
        
        let amtY:Float = ceil((height * Float(2.0)) / (tri_height) + Float(0.5) )
        let yOffset:Float = -((amtY*(tri_height) - height)/Float(2.0))
        
        let uva  = Vector2Make(0.0, 0.0)
        let uvb  = Vector2Make(1.0, 0.0)
        let uvc  = Vector2Make(0.5, 1.0)
        let norm = SCNVector3Make(0.0, 0.0, 1.0)
        
        var vertices:[SCNVector3] = [];
        var normals:[SCNVector3] = [];
        var uvs:[Vector2] = [];
        
        // creates a series of hexagons composed of 6 triangles each
        first: for( var i:Float = 0; i < amtX; i++ ) {
            var startX:Float = ((tri_width) * 1.5 * i)
            startX += xOffset
            for( var j:Float = 0; j < amtY; j++ ) {
                var startY:Float = (i%2==0) ? (tri_height*2*j) - (tri_height) : tri_height*2*j
                startY += yOffset;
                
                var scale = SCNVector3( x: tri_scale, y: tri_scale, z: 1.0 )
                var start = SCNVector3( x: startX, y: startY, z: 0.0 )
                //var start = SCNVector3( x: 0.0, y: 0.0, z: 0.0 )
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(r, 0.0, 0.0) * scale + start)
                vertices.append(SCNVector3Make(co, si, 0.0) * scale + start)

                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvb)
                uvs.append(uvc)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(co, si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(-co, si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvc)
                uvs.append(uvb)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(-co, si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(-r, 0.0, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvb)
                uvs.append(uvc)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(-r, 0.0, 0.0) * scale + start)
                vertices.append(SCNVector3Make(-co, -si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvc)
                uvs.append(uvb)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(-co, -si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(co, -si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvb)
                uvs.append(uvc)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(co, -si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(r, 0.0, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvc)
                uvs.append(uvb)
                
                //break first
            }
        }

        let primitiveCount = vertices.count / 3
        
        // Vertices
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals 
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Textures
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        
        var elements:[SCNGeometryElement] = []
        
        // Indexes
        
        for primitive in 0..<primitiveCount {
            
            let min:CInt = CInt(primitive * 3)
            let max:CInt = CInt((primitive + 1) * 3)
            var indices:[CInt] = []
            
            for var n:CInt = min; n < max; ++n {
                indices.append(n)
            }
            
            var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
            var indexElement = SCNGeometryElement(
                data: indexData,
                primitiveType: .Triangles,
                primitiveCount: 3,
                bytesPerIndex: sizeof(CInt)
            )
            
            elements.append(indexElement)
        }

        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: elements)
        
        if(self.textureSource == .Video) {
            geo.materials = [self.createMaterial()]
        }
        else if(self.textureSource == .Color) {
            var materials:[SCNMaterial] = []
            for var n = 0; n < primitiveCount; ++n {
                var material = SCNMaterial()
                material.diffuse.contents = UIColor.randomColor()
                materials.append(material)
            }
            geo.materials = materials
        }
        else if(self.textureSource == .Image) {
            var me = UIImage(named: "me2")
            var material = SCNMaterial()
            material.diffuse.contents = me
            geo.materials = [material]
        }
        
        return geo
    }
    
    func defineTriangle() -> SCNGeometry {

        // Vertices
        var vertices:[SCNVector3] = [
            SCNVector3Make(-1.0, -1.0, 0.0),
            SCNVector3Make(1.0, -1.0, 0.0),
            SCNVector3Make(0.0, 1.0, 0.0)
        ]
        
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        var normals:[SCNVector3] = [
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0)
        ]
        
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Texture
        var uvs:[Vector2] = [
            Vector2Make(0.0, 0.0),
            Vector2Make(1.0, 0.0),
            Vector2Make(0.5, 1.0)
        ]
        
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        // Indexes
        var indices:[CInt] = [0, 1, 2]
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: 1,
            bytesPerIndex: sizeof(CInt)
        )
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: [indexElement])
        
        let me2 = UIImage(named: "me2")
        
        // material
        var material = SCNMaterial()
        material.diffuse.contents  = me2
        material.doubleSided = true
        material.shininess = 1.0;
        geo.materials = [material];
        
        return geo
    }
    
    func defineCube() -> SCNGeometry {
        var halfSide:Float = 1.0;
        
        var positions = [
            SCNVector3Make(-halfSide, -halfSide,  halfSide),
            SCNVector3Make( halfSide, -halfSide,  halfSide),
            SCNVector3Make(-halfSide, -halfSide, -halfSide),
            SCNVector3Make( halfSide, -halfSide, -halfSide),
            SCNVector3Make(-halfSide,  halfSide,  halfSide),
            SCNVector3Make( halfSide,  halfSide,  halfSide),
            SCNVector3Make(-halfSide,  halfSide, -halfSide),
            SCNVector3Make( halfSide,  halfSide, -halfSide),
            
            // repeat exactly the same
            SCNVector3Make(-halfSide, -halfSide,  halfSide),
            SCNVector3Make( halfSide, -halfSide,  halfSide),
            SCNVector3Make(-halfSide, -halfSide, -halfSide),
            SCNVector3Make( halfSide, -halfSide, -halfSide),
            SCNVector3Make(-halfSide,  halfSide,  halfSide),
            SCNVector3Make( halfSide,  halfSide,  halfSide),
            SCNVector3Make(-halfSide,  halfSide, -halfSide),
            SCNVector3Make( halfSide,  halfSide, -halfSide),
            
            // repeat exactly the same
            SCNVector3Make(-halfSide, -halfSide,  halfSide),
            SCNVector3Make( halfSide, -halfSide,  halfSide),
            SCNVector3Make(-halfSide, -halfSide, -halfSide),
            SCNVector3Make( halfSide, -halfSide, -halfSide),
            SCNVector3Make(-halfSide,  halfSide,  halfSide),
            SCNVector3Make( halfSide,  halfSide,  halfSide),
            SCNVector3Make(-halfSide,  halfSide, -halfSide),
            SCNVector3Make( halfSide,  halfSide, -halfSide)
        ]
        
        var normals = [
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, -1, 0),
            
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make( 0, 1, 0),
            
            
            SCNVector3Make( 0, 0,  1),
            SCNVector3Make( 0, 0,  1),
            SCNVector3Make( 0, 0, -1),
            SCNVector3Make( 0, 0, -1),
            
            SCNVector3Make( 0, 0, 1),
            SCNVector3Make( 0, 0, 1),
            SCNVector3Make( 0, 0, -1),
            SCNVector3Make( 0, 0, -1),
            
            
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0),
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0),
            
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0),
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0)
        ]
        
        var indexes:[CInt] = [
            // bottom
            0, 2, 1,
            1, 2, 3,
            // back
            10, 14, 11,  // 2, 6, 3,   + 8
            11, 14, 15,  // 3, 6, 7,   + 8
            // left
            16, 20, 18,  // 0, 4, 2,   + 16
            18, 20, 22,  // 2, 4, 6,   + 16
            // right
            17, 19, 21,  // 1, 3, 5,   + 16
            19, 23, 21,  // 3, 7, 5,   + 16
            // front
            8,  9, 12,  // 0, 1, 4,   + 8
            9, 13, 12,  // 1, 5, 4,   + 8
            // top
            4, 5, 6,
            5, 7, 6
        ]
        
        var vertexSource = SCNGeometrySource(vertices: &positions, count: 24)
        var normalSource = SCNGeometrySource(normals: &normals, count: 24)
        
        var dat  = NSData(
            bytes: indexes,
            length: sizeof(CInt) * indexes.count
        )
        
        var ele = SCNGeometryElement(
            data: dat,
            primitiveType: .Triangles,
            primitiveCount: 12,
            bytesPerIndex: sizeof(CInt)
        )
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource], elements: [ele])
        
        var material = SCNMaterial()
        material.diffuse.contents  = UIColor.redColor()
        geo.materials = [material];
        
        return geo
    }
    
    func initVideoCapture() {
        
        let scnView = self.view as SCNView
        
        var textureCache: Unmanaged<CVOpenGLESTextureCacheRef>?
        var err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, scnView.eaglContext, nil, &textureCache)
        self.videoTextureCache = textureCache?.takeUnretainedValue()
        
        if (err != kCVReturnSuccess.value)
        {
            NSLog("Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
        
        self.session = AVCaptureSession()
        self.session!.beginConfiguration()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.session!.sessionPreset = AVCaptureSessionPreset640x480
        } else {
            self.session!.sessionPreset = AVCaptureSessionPresetPhoto
        }
        
        // Select a video device, make an input
        var device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if(device == nil) {
            NSLog("Error: No video device");
            return;
        }
        
        var error:NSError? = nil
        var deviceInput:AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(device, error: &error) as AVCaptureDeviceInput
        
        if error != nil {
            var alertView = UIAlertView(title: "Failed with error \(error?.code)", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Dismiss")
            alertView.show()
        }
        
        if self.session!.canAddInput(deviceInput) {
            self.session!.addInput(deviceInput)
        }
        else {
            NSLog("Error: Cannot add video capture device as input.");
        }
        
        var dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ]
        dataOutput.setSampleBufferDelegate(self, queue: self.videoBufferingDispatchQueue)
        
        if self.session!.canAddOutput(dataOutput) {
            self.session!.addOutput(dataOutput)
        }
        else {
            NSLog("Error: Cannot add video data capture device as output.");
        }
        
        self.session!.commitConfiguration()
        self.session!.startRunning()
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        NSLog("captureOutput");
        self.videoBufferQueue.push(sampleBuffer)
    }
    
    func processNextVideoTexture() {

        NSLog("processNextVideoTexture");
        
        var sampleBuffer:CMSampleBuffer? = self.videoBufferQueue.pop()
        if(sampleBuffer == nil) {
            return
        }
        
        var err: CVReturn = kCVReturnSuccess.value
        // Wow!
        var imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var pixelBuffer : CVPixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(Unmanaged<CVImageBuffer>.passUnretained(imageBuffer).toOpaque()).takeUnretainedValue()
        var width = CVPixelBufferGetWidth(pixelBuffer)
        var height = CVPixelBufferGetHeight(pixelBuffer)
        
        self.textureWidth = width
        self.textureHeight = height
        
        if (videoTextureCache == nil)
        {
            NSLog("No video texture cache");
            return;
        }
        
        self.cleanupTextures()
        
        // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
        // optimally from CVImageBufferRef.
        
        // Y-plane
        glActiveTexture(GLenum(GL_TEXTURE0))
        
        var unmanagedLumaTexture:Unmanaged<CVOpenGLESTexture>? = nil
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            self.videoTextureCache,
            imageBuffer,
            nil,
            GLenum(GL_TEXTURE_2D),
            GL_RED_EXT,
            GLsizei(textureWidth),
            GLsizei(textureHeight),
            GLenum(GL_RED_EXT),
            GLenum(GL_UNSIGNED_BYTE),
            0,
            &unmanagedLumaTexture)
        
        self.lumaTexture = unmanagedLumaTexture?.takeRetainedValue()
        
        if (err != kCVReturnSuccess.value) {
            NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        // UV-plane
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        
        var unmanagedChromaTexture:Unmanaged<CVOpenGLESTexture>? = nil
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            self.videoTextureCache,
            imageBuffer,
            nil,
            GLenum(GL_TEXTURE_2D),
            GL_RG_EXT,
            GLsizei(textureWidth/2),
            GLsizei(textureHeight/2),
            GLenum(GL_RG_EXT),
            GLenum(GL_UNSIGNED_BYTE),
            1,
            &unmanagedChromaTexture)
        
        self.chromaTexture = unmanagedChromaTexture?.takeRetainedValue()
        
        if (err != kCVReturnSuccess.value) {
            NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        NSLog("Warning: Sample buffer dropped.");
    }
    
    func cleanupTextures() {
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0)
    }
    
    func createMirror() {
        
        if !hasMirror {
            let scnView = self.view as SCNView
            let scene = scnView.scene
            
            let triNode = SCNNode()
            
            triNode.geometry = defineMirrorGrid()
            triNode.position = SCNVector3(x: 0, y: 0, z: 0)
            triNode.name = "mirrors"

            var videoAction = SCNAction.customActionWithDuration(10000000000, actionBlock:{
                (triNode:SCNNode!, elapsedTime:CGFloat) -> Void in
                NSLog("Running action")
                self.processNextVideoTexture()
            })

            triNode.runAction(videoAction)
         
            scene.rootNode.addChildNode(triNode)
            
            hasMirror = true
            
            if(self.textureSource == .Video) {
                self.initVideoCapture()
            }
        }
    }
    
    func createMaterial() -> SCNMaterial {
        
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
        //program.setSemantic(SCNModelViewProjectionTransform, forSymbol: "modelViewProjection", options: nil)
        
        program.delegate = self
        
        material.program = program
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
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {

        self.createMirror()
        
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
    
    func getExtents() -> (min:SCNVector3, max:SCNVector3) {
        
        let scnView = self.view as SCNView
        let camera = scnView.pointOfView.camera
        
        let projectedOrigin = scnView.projectPoint(SCNVector3Zero)
        
        println("projectedOrigin: (\(projectedOrigin.x), \(projectedOrigin.y), \(projectedOrigin.z))")
        
        var size = self.view.bounds.size
        
        var min = scnView.unprojectPoint(SCNVector3Make(0.0, Float(size.height), projectedOrigin.z))
        var max = scnView.unprojectPoint(SCNVector3Make(Float(size.width), 0.0, projectedOrigin.z))
        
        return (min, max)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
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
        // Release any cached data, images, etc that aren't in use.
    }
}
