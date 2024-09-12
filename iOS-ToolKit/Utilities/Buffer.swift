//
//  Buffer.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import Foundation

final class Buffer<T> {
    
    private let bufferQueue = DispatchQueue(label: "com.wavinDev.Buffer", qos: .background, attributes: .concurrent)
    
    private var items: [T] = []
    private var capacity: Int
    private var onCapacityReached: (([T]) -> ())?
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func onCapacity(perform onCapacityHandler: @escaping ([T]) -> ()) {
        self.onCapacityReached = onCapacityHandler
    }
    
    func addItem(_ item: T) {
        bufferQueue.async(flags: .barrier) {
            self.items.append(item)
            if self.items.count == self.capacity {
                self.onCapacityReached?(self.items)
                // keepingCapacity to true since items will need 60 entries for next inference
                self.items.removeAll(keepingCapacity: true)
            }
        }
    }
    
    func clear(keepingCapacity: Bool = false) {
        bufferQueue.async(flags: .barrier) {
            self.items.removeAll(keepingCapacity: keepingCapacity)
        }
    }
    
}
