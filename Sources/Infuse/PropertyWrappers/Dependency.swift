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
    private let resolution: Resolution
    private let name: Dependencies.Name?
    
    private let file: String
    private let line: Int
    
    public var wrappedValue: T {
        get {
            if let value = storage.value { return value }
            
            let instance = Dependencies.shared.get(T.self, name: name, file: file, line: line)
            storage.value = instance
            return instance
        }
        set {
            storage.value = newValue
        }
    }
    
    public init(_ resolution: Resolution = .lazy, name: Dependencies.Name? = nil, file: String = #file, line: Int = #line) {
        self.resolution = resolution
        self.name = name
        self.file = file
        self.line = line
        switch resolution {
        case .instant:
            _ = wrappedValue // Trigger resolving
        case .lazy:
            break
        }
    }
}

public extension Dependency {
    
    enum Resolution {
        case lazy
        case instant
    }
}
