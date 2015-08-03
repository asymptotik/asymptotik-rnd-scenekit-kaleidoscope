//
//  SCNMatrix4Extensions.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/5/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import SceneKit

extension SCNMatrix4 {
    var description:String {
        get {
            return "\(self.m11) \(self.m12) \(self.m13) \(self.m14) \n \(self.m21) \(self.m22) \(self.m23) \(self.m24) \n \(self.m31) \(self.m32) \(self.m33) \(self.m34) \n \(self.m41) \(self.m42) \(self.m43) \(self.m44) \n"
        }
    }
}

/**
* Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
* returns the result as a new SCNVector3.
*/
/*
func * (matrix: SCNMatrix4, vector: SCNVector4) -> SCNVector4 {
    
}
*/