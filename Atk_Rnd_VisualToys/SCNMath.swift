//
//  SCNMath.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/29/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import SceneKit

func SCNMatrix4Mult(matrix: SCNMatrix4, vector: SCNVector4) -> SCNVector4 {
    return SCNVector4Make(
        matrix.m11 * vector.x + matrix.m12 * vector.y + matrix.m13 * vector.z + matrix.m14 * vector.w,
        matrix.m21 * vector.x + matrix.m22 * vector.y + matrix.m23 * vector.z + matrix.m24 * vector.w,
        matrix.m31 * vector.x + matrix.m32 * vector.y + matrix.m33 * vector.z + matrix.m34 * vector.w,
        matrix.m41 * vector.x + matrix.m42 * vector.y + matrix.m43 * vector.z + matrix.m44 * vector.w
    )
}