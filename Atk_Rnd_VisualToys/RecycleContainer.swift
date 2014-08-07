//
//  RecycleContainer.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/6/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation

class RecycleContainer<T> {
    private var _items = [T]()
    private var _lock = LockHandle()
    
    func get() -> T? {
        var ret:T? = nil
        
        objc_sync_enter(_lock)
        if _items.count > 0 {
            ret = _items.removeLast()
        }
        objc_sync_exit(_lock)
        return ret
    }
    
    func put(item:T) {
        objc_sync_enter(_lock)
        _items.append(item)
        objc_sync_exit(_lock)
    }
}