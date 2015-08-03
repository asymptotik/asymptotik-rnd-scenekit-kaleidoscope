//
//  OpenGlUtils.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/29/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import OpenGLES

class OpenGlUtils {
    class func checkError(tag:String) {
        let error = glGetError()

        switch Int32(error) {
        case GL_INVALID_VALUE:
            NSLog("OpenGLES Error: tag: %@: GL_INVALID_VALUE", tag)
        case GL_INVALID_OPERATION:
            NSLog("OpenGLES Error: tag: %@: GL_INVALID_OPERATION", tag)
        case GL_STACK_OVERFLOW:
            NSLog("OpenGLES Error: tag: %@: GL_STACK_OVERFLOW", tag)
        case GL_STACK_UNDERFLOW:
            NSLog("OpenGLES Error: tag: %@: GL_STACK_UNDERFLOW", tag)
        case GL_OUT_OF_MEMORY:
            NSLog("OpenGLES Error: tag: %@: GL_OUT_OF_MEMORY", tag)
        default:
            return
        }
    }
    
    class func checkFrameBufferStatus(framebuffer:GLenum) {
        let status  = glCheckFramebufferStatus(framebuffer)
        
        switch Int32(status) {
        case GL_FRAMEBUFFER_UNDEFINED:
            NSLog("GL_FRAMEBUFFER_UNDEFINED")
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
            NSLog("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT")
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            NSLog("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT")
        case GL_FRAMEBUFFER_UNSUPPORTED:
            NSLog("GL_FRAMEBUFFER_UNSUPPORTED")
        case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
            NSLog("GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE")
        default:
            return
        }
    }
    
    class func dumpRenderbufferInfo() {
        var width:GLint = 0
        var height:GLint = 0
        var format:GLint = 0
        var red:GLint = 0
        var green:GLint = 0
        var blue:GLint = 0
        var alpha:GLint = 0
        
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &width)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &height)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_INTERNAL_FORMAT), &format)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_RED_SIZE), &red)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_GREEN_SIZE), &green)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_BLUE_SIZE), &blue)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_ALPHA_SIZE), &alpha)
        
        OpenGlUtils.checkError("glGetRenderbufferParameteriv")
        
        switch format {
        case GL_RGBA:
            NSLog("Format is GL_RGBA")
        case GL_RGBA4:
            NSLog("Format is GL_RGBA4")
        case GL_RGB5_A1:
            NSLog("Format is GL_RGB5_A1")
        case GL_RGB565:
            NSLog("Format is GL_RGB565")
        case GL_DEPTH_COMPONENT16:
            NSLog("Format is GL_DEPTH_COMPONENT16")
        case GL_STENCIL_INDEX8:
            NSLog("Format is GL_STENCIL_INDEX8")
        default:
            NSLog("Format is Unknown")
        }
    }
}