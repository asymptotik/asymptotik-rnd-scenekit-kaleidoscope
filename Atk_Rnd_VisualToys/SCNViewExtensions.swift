//
//  SCNViewExtensions.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/8/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation

import SceneKit

extension SCNView {
    /**
    * Gets the min and max global coordnate values based on the current projection
    */
    func getExtents() -> (min:SCNVector3, max:SCNVector3) {
        
        let projectedOrigin = self.projectPoint(SCNVector3Zero)
        
        print("projectedOrigin: (\(projectedOrigin.x), \(projectedOrigin.y), \(projectedOrigin.z))")
        
        let size = self.bounds.size
        let min = self.unprojectPoint(SCNVector3Make(0.0, Float(size.height), projectedOrigin.z))
        let max = self.unprojectPoint(SCNVector3Make(Float(size.width), 0.0, projectedOrigin.z))
        return (min, max)
    }
}