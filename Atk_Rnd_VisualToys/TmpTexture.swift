//
//  tmpTexture.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/30/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import OpenGLES
import GLKit

class TmpTexture {
    
    var spriteTexture:GLKTextureInfo
    
    init() {

        var theError:NSError? = nil
        
        var image = UIImage(named:"me2")
        var size = image.size
        
        NSLog("Image size (%lf, %lf)", image.size.width, image.size.height)
        
        self.spriteTexture = GLKTextureLoader.textureWithCGImage(image.CGImage, options: nil, error: &theError)
        if theError != nil {
            NSLog("Error creating texture: %@", theError!)
        }
    }
}