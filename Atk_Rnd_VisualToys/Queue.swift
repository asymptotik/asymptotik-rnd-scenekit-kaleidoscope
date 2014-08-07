//
//  Queue.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/6/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation

//
// should be an inner class of Queue, but inner classes and generics 
// crash the compiler, SourceKit (repeatedly) and occasionally XCode.
//
class _QueueItem<T> {
    let value: T!
    var next: _QueueItem?
    
    init(_ newvalue: T?) {
        self.value = newvalue
    }
}

//
// A standard queue (FIFO - First In First Out). Supports simultaneous
// adding and removing, but only one item can be added at a time, and 
// only one item can be removed at a time.
//
class Queue<T> {
    
    typealias Element = T
    
    private var _front: _QueueItem<Element>
    private var _back: _QueueItem<Element>
    var count = 0
    
    init () {
        // Insert dummy item. Will disappear when the first item is added.
        _back = _QueueItem(nil)
        _front = _back
    }
    
    /// Add a new item to the back of the queue.
    func enqueue (value: Element) {
        _back.next = _QueueItem(value)
        _back = _back.next!
        ++count
    }
    
    /// Return and remove the item at the front of the queue.
    func dequeue () -> Element? {
        if let newhead = _front.next {
            _front = newhead
            --count
            return newhead.value
        } else {
            return nil
        }
    }
    
    func isEmpty() -> Bool {
        return _front === _back
    }
}