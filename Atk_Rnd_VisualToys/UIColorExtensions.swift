//
//  UIColorExtensions.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/5/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    class func randomColor() -> UIColor {
        
        var r = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        var g = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        var b = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}