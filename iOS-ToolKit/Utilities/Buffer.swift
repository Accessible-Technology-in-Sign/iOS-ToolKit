//
//  Buffer.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import Foundation

final class Buffer<T> {
    
    private let bufferQueue = DispatchQueue(label: "com.wavinDev.Buffer", qos: .background, attributes: .concurrent)
    
    private var _items: [T] = []
    private var capacity: Int
    
    var items: [T] {
        bufferQueue.sync {
            return _items.suffix(capacity)
        }
    }
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func addItem(_ item: T) {
        bufferQueue.async(flags: .barrier) {
            self._items.append(item)
        }
    }
    
    func clear(keepingCapacity: Bool = false) {
        bufferQueue.async(flags: .barrier) {
            self._items.removeAll(keepingCapacity: keepingCapacity)
        }
    }
    
}
