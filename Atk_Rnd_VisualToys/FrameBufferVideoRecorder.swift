//
//  FrameBufferVideoRecorder.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/22/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia
import CoreVideo
import OpenGLES

enum FrameBufferVideoRecorderStatus : Int {
    case Unknown
    case Writing
    case Completed
    case Failed
    case Cancelled
    
    var description : String {
        switch self {
            // Use Internationalization, as appropriate.
            case .Unknown: return "Unknown"
            case .Writing: return "Writing"
            case .Completed: return "Completed"
            case .Failed: return "Failed"
            case .Cancelled: return "Cancelled"
        }
    }
}

extension AVAssetWriterStatus  {

    var description : String {
        switch self {
            case .Unknown: return "Unknown"
            case .Writing: return "Writing"
            case .Completed: return "Completed"
            case .Failed: return "Failed"
            case .Cancelled: return "Cancelled"
        }
    }
}

class FrameBufferVideoRecorder : NSObject {

    var assetWriter:AVAssetWriter! = nil
    var assetWriterVideoInput:AVAssetWriterInput! = nil
    var assetWriterPixelBufferInput:AVAssetWriterInputPixelBufferAdaptor! = nil
    var movieUrl:NSURL! = nil
    var width:GLsizei = 0;
    var height:GLsizei = 0;
    var startTime:CFTimeInterval = 0
    
    var framebuffer:GLuint = 0
    var videoTextureCache: CVOpenGLESTextureCache? = nil
    var renderTexture:CVOpenGLESTexture? = nil
    var pixelBuffer:CVPixelBuffer? = nil
    
    var target:GLenum {
        get { return CVOpenGLESTextureGetTarget(self.renderTexture!) }
    }
    
    var name:GLuint {
        get { return CVOpenGLESTextureGetName(self.renderTexture!) }
    }
    
    init(movieUrl: NSURL, width:GLsizei, height:GLsizei) {
        self.movieUrl = movieUrl
        self.width = width
        self.height = height
    }
    
    func initVideoRecorder(context: EAGLContext) {
        
        var error:NSError? = nil
        
        do {
            self.assetWriter = try AVAssetWriter(URL: self.movieUrl, fileType:AVFileTypeAppleM4V)
        } catch let error1 as NSError {
            error = error1
            self.assetWriter = nil
        }

        if (error != nil) {
            NSLog("Error: %@", error!)
        }
        
        let compressionSettings = [
            //AVVideoMaxKeyFrameIntervalKey: 1,
            AVVideoAverageBitRateKey: 10 * 1000000
        ]
        
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber(int: self.width),
            AVVideoHeightKey: NSNumber(int: self.height),
            AVVideoCompressionPropertiesKey: compressionSettings
        ]

        self.assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings:outputSettings);
        self.assetWriterVideoInput.expectsMediaDataInRealTime = true;
        self.assetWriterVideoInput.transform = CGAffineTransformIdentity;
    
        // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
        
        let sourcePixelBufferAttributesDictionary : [String: AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: NSNumber(int: self.width),
            kCVPixelBufferHeightKey as String: NSNumber(int: self.height)
        ]

        self.assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.assetWriterVideoInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)

        if self.assetWriter.canAddInput(assetWriterVideoInput) {
            self.assetWriter.addInput(assetWriterVideoInput)
        }
        else {
             NSLog("Cannot add asset writer")
        }
        
        self.assetWriter.startWriting()
        self.assetWriter.startSessionAtSourceTime(kCMTimeZero)
        
        self.startTime = 0.0
    }
    
    func generateFramebuffer(context: EAGLContext) {
        
        glGenFramebuffers(1, &self.framebuffer);
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.framebuffer)
        
        // TODO: Combine with video reader texture cache
        var textureCache: CVOpenGLESTextureCache? = nil
        var err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
        
        self.videoTextureCache = textureCache
        
        if (err != kCVReturnSuccess) {
            NSLog("Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
        
        var pixelBufferUnmanaged:CVPixelBuffer? = nil;
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput.pixelBufferPool!, &pixelBufferUnmanaged);
        self.pixelBuffer = pixelBufferUnmanaged
        
        if status != kCVReturnSuccess {
            NSLog("Problem creating pixel buffer: %@", CVReturn.stringValue(status))
        }
        
        if self.pixelBuffer == nil {
            NSLog("Problem appending pixel buffer. Pixel buffer is nil");
            return;
        }
        
        var unmanagedRenderTexture:CVOpenGLESTexture? = nil
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            self.videoTextureCache!,
            self.pixelBuffer!,
            nil,
            GLenum(GL_TEXTURE_2D),
            GL_RGBA,
            GLsizei(self.width),
            GLsizei(self.height),
            GLenum(GL_BGRA),
            GLenum(GL_UNSIGNED_BYTE),
            0,
            &unmanagedRenderTexture)
        
        self.renderTexture = unmanagedRenderTexture
        
        if (err != kCVReturnSuccess) {
            NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.renderTexture!), CVOpenGLESTextureGetName(self.renderTexture!));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), CVOpenGLESTextureGetName(self.renderTexture!), 0);
    }
    
    func bindRenderTextureFramebuffer() {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
    }
    
    func grabFrameFromRenderTexture(time:NSTimeInterval) {
        
        if !self.assetWriterVideoInput.readyForMoreMediaData {
            return;
        }
        
        if self.startTime == 0  {
            self.startTime = time
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, 0)

        let currentTime:CMTime = CMTimeMakeWithSeconds(time - self.startTime, 120);
        
        if(!assetWriterPixelBufferInput.appendPixelBuffer(self.pixelBuffer!, withPresentationTime:currentTime)) {
            NSLog("Problem appending pixel buffer at time: %lld", currentTime.value)
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, 0)
    }

    func finish(handler: ((status:FrameBufferVideoRecorderStatus) -> Void)!) {
        glDeleteFramebuffers(1, &self.framebuffer)
        self.assetWriterVideoInput.markAsFinished()
        self.assetWriter.finishWritingWithCompletionHandler { () -> Void in
            if(handler != nil) {
                var status:FrameBufferVideoRecorderStatus
                
                switch self.assetWriter.status {
                case .Unknown:
                    status = .Unknown
                case .Writing:
                    status = .Writing
                case .Completed:
                    status = .Completed
                case .Failed:
                    status = .Failed
                case .Cancelled:
                    status = .Cancelled
                }
                
                handler(status: status)
            }
        }
    }
}