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
    var videoTextureCache: CVOpenGLESTextureCacheRef? = nil
    
    var textureWidth: size_t = 0
    var textureHeight: size_t = 0
    var lumaTexture: CVOpenGLESTexture? = nil
    var chromaTexture: CVOpenGLESTexture? = nil
    
    var videoBufferingDispatchQueue = dispatch_queue_create("video displatch queue",  DISPATCH_QUEUE_CONCURRENT)
    var videoBufferQueue = CircularQueue<CMSampleBuffer>(size:3)
    
    func initVideoCapture(context:EAGLContext) {

        var textureCache: Unmanaged<CVOpenGLESTextureCacheRef>?
        var err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
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
            self.session!.sessionPreset = AVCaptureSessionPresetPhoto //AVCaptureSessionPresetiFrame960x540
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
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0)
    }
    
    private var _videoFrameProcessingRate = FrequencyCounter();
    func processNextVideoTexture() {
        
        //NSLog("processNextVideoTexture");
        
        var sampleBuffer:CMSampleBuffer? = self.videoBufferQueue.pop()
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
        var err: CVReturn = kCVReturnSuccess.value
        
        if sampleBuffer != nil {
            
            imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            var pixelBuffer : CVPixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()).takeUnretainedValue()
            var width = CVPixelBufferGetWidth(pixelBuffer)
            var height = CVPixelBufferGetHeight(pixelBuffer)
            
            self.textureWidth = width
            self.textureHeight = height
        }
        
        self.cleanupTextures()
        
        // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
        // optimally from CVImageBufferRef.
        
        // Y-plane
        glActiveTexture(GLenum(GL_TEXTURE0))
        
        if imageBuffer != nil {
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
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        // UV-plane
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        
        if imageBuffer != nil {
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
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
    }
}