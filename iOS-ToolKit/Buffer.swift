//
//  Buffer.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import Foundation

final class Buffer<T> {
    
    private let bufferQueue = DispatchQueue(label: "com.wavinDev.Buffer", qos: .background)
    
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
        bufferQueue.sync {
            self.items.append(item)
            if self.items.count == capacity {
                onCapacityReached?(self.items)
                // keepingCapacity to true since items will need 60 entries for next inference
                items.removeAll(keepingCapacity: true)
            }
        }
    }
    
    func clear(keepingCapacity: Bool = false) {
        bufferQueue.sync {
            self.items.removeAll(keepingCapacity: keepingCapacity)
        }
    }
    
}
