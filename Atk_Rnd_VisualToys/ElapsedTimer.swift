//
//  ElapsedTime.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/7/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import QuartzCore

class ElapsedTimer {
    private var _start:CFTimeInterval = 0

    func start() {
        _start = CACurrentMediaTime()
    }

    var elapsed:CFTimeInterval {
        get {
            var end:CFTimeInterval = 0
            end = CACurrentMediaTime()
        
            return end - _start
        }
    }
}