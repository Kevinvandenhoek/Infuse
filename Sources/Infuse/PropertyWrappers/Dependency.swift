//
//  Dependency.swift
//  
//
//  Created by Kevin van den Hoek on 11/07/2023.
//

import Foundation

@propertyWrapper
public struct Dependency<T> {
    
    private class Storage {
        var value: T? = nil
    }
    
    private let storage = Storage()
    
    public var wrappedValue: T {
        if let value = storage.value { return value }
        
        let instance = Dependencies.shared.get(T.self)
        storage.value = instance
        return instance
    }
    
    public init() {
        
    }
}
