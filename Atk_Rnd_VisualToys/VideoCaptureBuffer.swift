//
//  VideoCaptureBuffer.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/8/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreVideo
import OpenGLES

class VideoCaptureBuffer : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession? = nil
    var videoTextureCache: CVOpenGLESTextureCache? = nil
    
    var textureWidth: size_t = 0
    var textureHeight: size_t = 0
    var lumaTexture: CVOpenGLESTexture? = nil
    var chromaTexture: CVOpenGLESTexture? = nil
    
    var videoBufferingDispatchQueue = dispatch_queue_create("video displatch queue",  DISPATCH_QUEUE_CONCURRENT)
    var videoBufferQueue = CircularQueue<CMSampleBuffer>(size:3)
    
    var isUsingFrontFacingCamera = false
    
    var captureDeviceFormat:AVCaptureDeviceFormat? = nil
    var captureDevice:AVCaptureDevice? = nil
    
    func initVideoCapture(context:EAGLContext) {

        var textureCache:CVOpenGLESTextureCache? = nil;
        let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
        
        if (err != kCVReturnSuccess)
        {
            NSLog("Error at CVOpenGLESTextureCacheCreate %@", CVReturn.stringValue(err));
            return;
        }
        
        self.videoTextureCache = textureCache
        
        self.session = AVCaptureSession()
        self.session!.beginConfiguration()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.session!.sessionPreset = AVCaptureSessionPresetPhoto
        } else {
            self.session!.sessionPreset = AVCaptureSessionPresetPhoto //AVCaptureSessionPresetiFrame960x540
        }
        
        // Select a video device, make an input
        self.captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if(self.captureDevice == nil) {
            NSLog("Error: No video device");
            return;
        }
        
        self.captureDeviceFormat = self.captureDevice!.activeFormat

        do {
            let error:NSError? = nil
            let deviceInput:AVCaptureDeviceInput = try AVCaptureDeviceInput(device: self.captureDevice)
            
            if error != nil {
                let alertView = UIAlertView(title: "Failed with error \(error?.code)", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Dismiss")
                alertView.show()
            }
            
            if self.session!.canAddInput(deviceInput) {
                self.session!.addInput(deviceInput)
            }
            else {
                NSLog("Error: Cannot add video capture device as input.");
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) ]
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
        catch _ {
            NSLog("Error: Creating AVCaptureDeviceInput.");
        }
    }
    
    private var _videoCaptureRate = FrequencyCounter();
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        if _videoCaptureRate.count == 0 {
            _videoCaptureRate.start()
        }
        _videoCaptureRate.increment()
        if _videoCaptureRate.count % 30 == 0 {
            //NSLog("Video Capture Rate: \(_videoCaptureRate.frequency)/sec")
        }
        self.videoBufferQueue.push(sampleBuffer)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        NSLog("Warning: Sample buffer dropped.");
    }
    
    func cleanupTextures() {
        CVOpenGLESTextureCacheFlush(self.videoTextureCache!, 0)
    }
    
    private var _videoFrameProcessingRate = FrequencyCounter();
    func processNextVideoTexture() {
        
        //NSLog("processNextVideoTexture");
        
        let sampleBuffer:CMSampleBuffer? = self.videoBufferQueue.pop()
        if sampleBuffer == nil && self.lumaTexture == nil && self.chromaTexture == nil {
            return
        }
        
        if _videoFrameProcessingRate.count == 0 {
            _videoFrameProcessingRate.start()
        }
        _videoFrameProcessingRate.increment()
        if _videoFrameProcessingRate.count % 30 == 0 {
            //NSLog("Video Frame Processing Rate: \(_videoFrameProcessingRate.frequency)/sec")
        }
        
        var imageBuffer:CVImageBuffer? = nil
        var err: CVReturn = kCVReturnSuccess
        
        if sampleBuffer != nil {
            
            imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)
            let pixelBuffer : CVPixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()).takeUnretainedValue()
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            self.textureWidth = width
            self.textureHeight = height
        }
        
        self.cleanupTextures()
        
        // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
        // optimally from CVImageBufferRef.
        
        // Y-plane
        glActiveTexture(GLenum(GL_TEXTURE0))
        
        if imageBuffer != nil {
            var unmanagedLumaTexture:CVOpenGLESTexture? = nil
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                self.videoTextureCache!,
                imageBuffer!,
                nil,
                GLenum(GL_TEXTURE_2D),
                GL_RED_EXT,
                GLsizei(textureWidth),
                GLsizei(textureHeight),
                GLenum(GL_RED_EXT),
                GLenum(GL_UNSIGNED_BYTE),
                0,
                &unmanagedLumaTexture)
            
            self.lumaTexture = unmanagedLumaTexture
            
            if (err != kCVReturnSuccess) {
                NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture!), CVOpenGLESTextureGetName(self.lumaTexture!));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        // UV-plane
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        
        if imageBuffer != nil {
            
            var unmanagedChromaTexture:CVOpenGLESTexture? = nil
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                self.videoTextureCache!,
                imageBuffer!,
                nil,
                GLenum(GL_TEXTURE_2D),
                GL_RG_EXT,
                GLsizei(textureWidth/2),
                GLsizei(textureHeight/2),
                GLenum(GL_RG_EXT),
                GLenum(GL_UNSIGNED_BYTE),
                1,
                &unmanagedChromaTexture)
            
            self.chromaTexture = unmanagedChromaTexture
            
            if (err != kCVReturnSuccess) {
                NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture!), CVOpenGLESTextureGetName(self.chromaTexture!));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
    }
    
    func switchCameras() {

        var desiredPosition : AVCaptureDevicePosition = AVCaptureDevicePosition.Unspecified
        if isUsingFrontFacingCamera {
            desiredPosition = AVCaptureDevicePosition.Back
        }
        else {
            desiredPosition = AVCaptureDevicePosition.Front
        }
    
        for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            let captureDevice = device as! AVCaptureDevice
            if captureDevice.position == desiredPosition {
                session!.beginConfiguration()
                
                self.captureDeviceFormat = captureDevice.activeFormat
                self.captureDevice = captureDevice
                
                do {
                    let input = try AVCaptureDeviceInput(device: captureDevice)
                    for oldInput in session!.inputs {
                        session!.removeInput(oldInput as! AVCaptureInput)
                    }
                    session!.addInput(input)
                    session!.commitConfiguration()
                }
                catch _ {
                    NSLog("Error: Creating AVCaptureDeviceInput.");
                }
                break
            }
        }
        
        isUsingFrontFacingCamera = !isUsingFrontFacingCamera
    }
    
    var maxZoom:CGFloat {
        get {
            var ret = CGFloat(0.0)
            if self.captureDeviceFormat != nil {
                ret = self.captureDeviceFormat!.videoMaxZoomFactor / (self.isUsingFrontFacingCamera ? 10.0 : 4.0)
            }
            return ret
        }
    }
    
    var zoom:CGFloat {
        get {
            var ret = CGFloat(0.0)
            if self.captureDevice != nil {
                ret = self.captureDevice!.videoZoomFactor
            }
            return ret
        }
        
        set {
            var value = newValue
            if self.captureDevice != nil && self.maxZoom > 0.0 {
                do {
                    try self.captureDevice!.lockForConfiguration()
                } catch _ {
                    NSLog("Error: lockForConfiguration.");
                }
                if newValue < 0.0 { value = 0.0 }
                if newValue > self.maxZoom { value = self.maxZoom }
                NSLog("Setting zom to: %f", value)
                self.captureDevice!.videoZoomFactor = value
                self.captureDevice!.unlockForConfiguration()
            }
        }
    }
}