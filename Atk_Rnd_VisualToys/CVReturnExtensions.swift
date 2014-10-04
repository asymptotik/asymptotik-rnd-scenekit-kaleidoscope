//
//  CVReturn+Extensions.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/27/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import CoreVideo

extension _CVReturn {
    
    static func stringValue(value:CVReturn) -> String {

        var ret = ""
            
        switch value {
        case kCVReturnSuccess.value:
            ret = "kCVReturnSuccess"
         case kCVReturnFirst.value:
            ret = "kCVReturnFirst"
         case kCVReturnLast.value:
            ret = "kCVReturnLast"
         case kCVReturnInvalidArgument.value:
            ret = "kCVReturnInvalidArgument"
         case kCVReturnAllocationFailed.value:
            ret = "kCVReturnAllocationFailed"
        case kCVReturnInvalidDisplay.value:
            ret = "kCVReturnInvalidDisplay"
        case kCVReturnDisplayLinkAlreadyRunning.value:
            ret = "kCVReturnDisplayLinkAlreadyRunning"
        case kCVReturnDisplayLinkNotRunning.value:
            ret = "kCVReturnDisplayLinkNotRunning"
        case kCVReturnDisplayLinkCallbacksNotSet.value:
            ret = "kCVReturnDisplayLinkCallbacksNotSet"
        case kCVReturnInvalidPixelFormat.value:
            ret = "kCVReturnInvalidPixelFormat"
        case kCVReturnInvalidSize.value:
            ret = "kCVReturnInvalidSize"
        case kCVReturnInvalidPixelBufferAttributes.value:
            ret = "kCVReturnInvalidPixelBufferAttributes"
        case kCVReturnPixelBufferNotOpenGLCompatible.value:
            ret = "kCVReturnPixelBufferNotOpenGLCompatible"
        case kCVReturnPixelBufferNotMetalCompatible.value:
            ret = "kCVReturnPixelBufferNotMetalCompatible"
        case kCVReturnWouldExceedAllocationThreshold.value:
            ret = "kCVReturnWouldExceedAllocationThreshold"
        case kCVReturnPoolAllocationFailed.value:
            ret = "kCVReturnPoolAllocationFailed"
        case kCVReturnInvalidPoolAttributes.value:
            ret = "kCVReturnInvalidPoolAttributes"
        default:
            ret = "Unknown"
        }
        
        return ret;
    }
}