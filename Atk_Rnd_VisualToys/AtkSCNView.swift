//
//  AtkSCNView.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/29/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import UIKit
import OpenGLES
import SceneKit
import GLKit

class AtkSCNView : EAGLView {
    
    var renderer:SCNRenderer? = nil
    var scene:SCNScene? {
        get { return self.renderer?.scene }
        set { self.renderer!.scene = newValue }
    }
    
    required init?(coder: NSCoder) {

        super.init(coder: coder)
        
        let ctx = self.context
        self.renderer = SCNRenderer(context: ctx!, options: nil)
    }
    
    
    func gluUnProject(winx:GLfloat, winy:GLfloat, winz:GLfloat, modelMatrix:SCNMatrix4, projMatrix:SCNMatrix4, viewport:Array<GLint>, inout objx:GLfloat, inout objy:GLfloat, inout objz:GLfloat) -> Bool
    {
        var finalMatrix:SCNMatrix4
        var inv:SCNVector4 = SCNVector4Make(winx, winy, winz, 1.0)
        var outv:SCNVector4
        
        //double in[4];
        //double out[4];
    
        finalMatrix = SCNMatrix4Mult(modelMatrix, projMatrix)
        finalMatrix = SCNMatrix4Invert(finalMatrix)
        
        /* Map x and y from window coordinates */
        inv.x = (inv.x - GLfloat(viewport[0])) / GLfloat(viewport[2])
        inv.y = (inv.y - GLfloat(viewport[1])) / GLfloat(viewport[3])
    
        /* Map to range -1 to 1 */
        inv.x = inv.x * 2 - 1;
        inv.y = inv.y * 2 - 1;
        inv.z = inv.z * 2 - 1;
    
        outv = SCNMatrix4Mult(finalMatrix, vector: inv)
        
        if outv.w == 0.0 {
            return false
        }
        
        outv.x /= outv.w
        outv.y /= outv.w
        outv.z /= outv.w
        
        objx = outv.x
        objy = outv.y
        objz = outv.z
        
        return true
    }

}