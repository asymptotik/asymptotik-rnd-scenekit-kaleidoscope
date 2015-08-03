//
//  CVReturn+Extensions.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/27/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import CoreVideo

extension CVReturn {
    
    static func stringValue(value:CVReturn) -> String {

        var ret = ""
            
        switch value {
        case kCVReturnSuccess:
            ret = "kCVReturnSuccess"
         case kCVReturnFirst:
            ret = "kCVReturnFirst"
         case kCVReturnLast:
            ret = "kCVReturnLast"
         case kCVReturnInvalidArgument:
            ret = "kCVReturnInvalidArgument"
         case kCVReturnAllocationFailed:
            ret = "kCVReturnAllocationFailed"
        case kCVReturnInvalidDisplay:
            ret = "kCVReturnInvalidDisplay"
        case kCVReturnDisplayLinkAlreadyRunning:
            ret = "kCVReturnDisplayLinkAlreadyRunning"
        case kCVReturnDisplayLinkNotRunning:
            ret = "kCVReturnDisplayLinkNotRunning"
        case kCVReturnDisplayLinkCallbacksNotSet:
            ret = "kCVReturnDisplayLinkCallbacksNotSet"
        case kCVReturnInvalidPixelFormat:
            ret = "kCVReturnInvalidPixelFormat"
        case kCVReturnInvalidSize:
            ret = "kCVReturnInvalidSize"
        case kCVReturnInvalidPixelBufferAttributes:
            ret = "kCVReturnInvalidPixelBufferAttributes"
        case kCVReturnPixelBufferNotOpenGLCompatible:
            ret = "kCVReturnPixelBufferNotOpenGLCompatible"
        case kCVReturnPixelBufferNotMetalCompatible:
            ret = "kCVReturnPixelBufferNotMetalCompatible"
        case kCVReturnWouldExceedAllocationThreshold:
            ret = "kCVReturnWouldExceedAllocationThreshold"
        case kCVReturnPoolAllocationFailed:
            ret = "kCVReturnPoolAllocationFailed"
        case kCVReturnInvalidPoolAttributes:
            ret = "kCVReturnInvalidPoolAttributes"
        default:
            ret = "Unknown"
        }
        
        return ret;
    }
}