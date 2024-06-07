//
//  Dependency.swift
//
//
//  Created by Kevin van den Hoek on 11/07/2023.
//

import Foundation

@propertyWrapper
public struct Dependency<T> {
    
    private let storage: Storage
    private let resolution: Resolution
    
    public var wrappedValue: T {
        get {
            switch storage {
            case .instant(let value):
                return value
            case .lazy(let storageContainer):
                return storageContainer.get()
            }
        }
        set {
            switch storage {
            case .instant:
                assertionFailure("overwriting value not supported for dependencies with instant resolution")
            case .lazy(let storageContainer):
                storageContainer.value = newValue
            }
        }
    }
    
    public init(_ resolution: Resolution = .lazy, name: Dependencies.Name? = nil, file: String = #file, line: Int = #line) {
        self.resolution = resolution
        switch resolution {
        case .instant:
            storage = .instant(Dependencies.shared.get(T.self, name: name, file: file, line: line))
        case .lazy:
            storage = .lazy(StorageContainer(name: name, file: file, line: line))
        }
    }
}

public extension Dependency {
    
    enum Resolution {
        case lazy
        case instant
    }
    
    private enum Storage {
        case instant(T)
        case lazy(StorageContainer)
    }
    
    private class StorageContainer {
        let name: Dependencies.Name?
        let file: String
        let line: Int
        var value: T? = nil
        
        init(name: Dependencies.Name?, file: String, line: Int) {
            self.name = name
            self.file = file
            self.line = line
        }
        
        func get() -> T {
            if let value {
                return value
            } else {
                let value = Dependencies.shared.get(T.self, name: name, file: file, line: line)
                self.value = value
                return value
            }
        }
    }
}
