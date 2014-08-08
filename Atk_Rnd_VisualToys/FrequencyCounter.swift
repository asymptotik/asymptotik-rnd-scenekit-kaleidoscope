//
//  FrequencyCounter.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/7/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import QuartzCore

class FrequencyCounter {
    
    private var _elapsedTimer:ElapsedTimer = ElapsedTimer()
    private var _count:Int = 0
    
    func start() {
        _elapsedTimer.start()
        _count = 0
    }
    
    func increment() {
        _count += 1
    }
    
    var count:Int {
        get {
            return _count
        }
    }
    
    var frequency:Double {
        get {
            var elapsed = _elapsedTimer.elapsed
            if elapsed <= 0 {
                return 0.0
            }
            else {
                return Double(NSTimeInterval(_count) / elapsed)
            }
        }
    }
}