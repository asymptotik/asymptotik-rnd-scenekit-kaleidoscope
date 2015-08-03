//
//  EAGLSCNView.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/29/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import UIKit
import OpenGLES

class EAGLView : UIView {
    
    // The pixel dimensions of the CAEAGLLayer.
    private(set) var framebufferWidth:GLint = 0
    private(set) var framebufferHeight:GLint = 0

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
    private(set) var defaultFramebuffer:GLuint = 0
    private(set) var colorRenderbuffer:GLuint = 0
    private(set) var depthRenderbuffer:GLuint = 0
    private(set) var context:EAGLContext? = nil {
        willSet {
            self.deleteFramebuffer()
        }
    }
    
    var eaglLayer:CAEAGLLayer {
        get { return self.layer as! CAEAGLLayer }
    }
    
    override class func layerClass() -> AnyClass {
        return CAEAGLLayer.classForCoder()
    }

    required init?(coder:NSCoder) {
        super.init(coder:coder)
        
        let eaglLayer = self.eaglLayer
        
        eaglLayer.opaque = true
        eaglLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking: NSNumber(bool:false),
            kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
        ]
    }
    
    func createFramebuffer() {
        if (self.context != nil && self.defaultFramebuffer == 0) {
            EAGLContext.setCurrentContext(self.context)
        
            // Create default framebuffer object.
            glGenFramebuffers(1, &self.defaultFramebuffer);
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.defaultFramebuffer);
            
            // Create color render buffer and allocate backing store.
            glGenRenderbuffers(1, &self.colorRenderbuffer);
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.colorRenderbuffer)
            self.context?.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: self.eaglLayer)
                
            glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &self.framebufferWidth)
            glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &self.framebufferHeight)
            
            glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.colorRenderbuffer)
            
            let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
            if (Int32(status) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog("Failed to make complete framebuffer object %x", status)
            }
        }
    }
    
    func deleteFramebuffer() {
        if (self.context != nil) {
            EAGLContext.setCurrentContext(self.context)
            
            if (self.defaultFramebuffer > 0) {
                glDeleteFramebuffers(1, &self.defaultFramebuffer);
                self.defaultFramebuffer = 0;
            }
            
            if (self.colorRenderbuffer > 0) {
                glDeleteRenderbuffers(1, &self.colorRenderbuffer);
                self.colorRenderbuffer = 0;
            }
        }
    }
    
    func bindFramebuffer() {
        if (self.context != nil) {
            EAGLContext.setCurrentContext(self.context)
        
            if self.defaultFramebuffer == 0 {
                self.createFramebuffer()
            }
        
            glBindFramebuffer(GLenum(GL_RENDERBUFFER), self.defaultFramebuffer)
            glViewport(0, 0, self.framebufferWidth, self.framebufferHeight)
        }
    }
    
    func presentFramebuffer() -> Bool
    {
        var success = false
    
        if self.context != nil {
            EAGLContext.setCurrentContext(self.context)
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.colorRenderbuffer)
            success = self.context!.presentRenderbuffer(Int(GL_RENDERBUFFER))
        }
    
        return success
    }
    
    override func layoutSubviews() {
        // The framebuffer will be re-created at the beginning of the next setFramebuffer method call.
        self.deleteFramebuffer()
    }
}

