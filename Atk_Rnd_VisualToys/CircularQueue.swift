//
//  CircularQueue.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/6/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation

public class CircularQueue<T> {
    
    private var _lock = LockHandle()
    
    private var _elements:[T?]
    
    /** Array index of first (oldest) queue element. */
    private var _start = 0;
    
    /**
    * Index mod maxElements of the array position following the last queue
    * element.  Queue elements start at elements[start] and "wrap around"
    * elements[maxElements-1], ending at elements[decrement(end)].
    * For example, elements = {c,a,b}, start=1, end=1 corresponds to
    * the queue [a,b,c].
    */
    private var _end = 0;
    
    /** Flag to indicate if the queue is currently full. */
    private var _full = false;
    
    /** Capacity of the queue. */
    private var _maxElements:Int;
    
    convenience init() {
        self.init(size: 16)
    }
    
    init(size: Int) {
        _elements = [T?](count: size, repeatedValue: nil)
        _maxElements = size
    }
    
    var size:Int {
        
        get {
            var size = 0
            
            if(_end < _start) {
                size = _maxElements - _start + _end
            } else if (_end == _start) {
                size = _full ? _maxElements : 0;
            } else {
                size = _end - _start;
            }
            
            return size
        }
    }
    
    var isEmpty:Bool {
        get {
            return self.size == 0
        }
    }
    
    var isFull:Bool {
        get {
            return false
        }
    }
    
    var isAtCapacity:Bool {
        get {
            return self.size == _maxElements
        }
    }
    
    var maxSize:Int {
        get {
            return _maxElements
        }
    }
    
    func clear() {
        _full = false
        _start = 0
        _end = 0
        
        for var n = 0; n < _elements.count; ++n {
            _elements[n] = nil
        }
    }
    
    func push(element:T) -> Bool {
        
        objc_sync_enter(_lock)
        if self.isAtCapacity {
            _pop()
        }
        
        _elements[_end++] = element
        
        if _end >= _maxElements {
            _end = 0
        }
        
        if _end == _start {
            _full = true
        }
        objc_sync_exit(_lock)
        
        return true
    }
    
    private func _pop() -> T? {
        if self.isEmpty {
            return nil
        }
        
        var element:T? = _elements[_start]
        if element != nil {
            _elements[_start++] = nil
            if _start >= _maxElements {
                _start = 0
            }
            _full = false
        }
        
        return element
        
    }
    
    func pop() -> T? {
        objc_sync_enter(_lock)
        let ret = _pop()
        objc_sync_exit(_lock)
        return ret
    }
    
    func get(index:Int) -> T? {
        var sz:Int = self.size
        if index < 0 || index >= sz {
            return nil
        }
        
        var idx:Int = (_start + index) % _maxElements
        return _elements[idx]
    }
}