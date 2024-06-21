//
//  Dependencies.swift
//
//
//  Created by Kevin van den Hoek on 11/07/2023.
//

import Foundation

@discardableResult
private func syncSafe<T>(_ work: () -> T) -> T {
    guard !Thread.isMainThread else {
        return work()
    }
    
    return DispatchQueue.main.sync {
        return work()
    }
}

private class ThreadLock {
    
    let lock = NSRecursiveLock()
    var enableLogging: Bool = false
    var forceMainThread: Bool = false
    
    private var lockHolder: String = ""
    
    func performWithLock<T>(id: String, work: () -> T) -> T {
        guard !forceMainThread else {
            return syncSafe { work() }
        }
        if enableLogging {
            print("💉 will lock for \(id), currently held by \(lockHolder)")
        }
        lock.lock()
        if enableLogging {
            lockHolder = id
        }
        let result = work()
        if enableLogging {
            lockHolder = "none"
            print("💉 completedWork from \(id)")
        }
        lock.unlock()
        return result
    }
}

public class Dependencies {
    
    public static let shared = Dependencies()
    
    private var registry: [HashKey: Factory] = [:]
}

public extension Dependencies {
    
    enum Scope {
        public typealias CacheID = String
        
        case transient
        case singleton
        case cached(id: CacheID? = nil)
        
        var shouldCache: Bool {
            switch self {
            case .cached, .singleton:
                return true
            case .transient:
                return false
            }
        }
    }
    
    struct Options<Service> {
        
        private let factory: Factory
        private let key: HashKey
        private let dependencies: Dependencies
        private let lock = ThreadLock()
        
        fileprivate init(_ factory: Factory, key: HashKey, dependencies: Dependencies) {
            self.factory = factory
            self.key = key
            self.dependencies = dependencies
        }
        
        @discardableResult
        public func scope(_ scope: Dependencies.Scope, file: String = #file, line: Int = #line) -> Self {
            lock.performWithLock(id: "\(file.split(separator: "/").last ?? "") - \(line)") {
                factory.scope = scope
            }
            return self
        }
        
        @discardableResult
        public func implements<T>(_ type: T.Type, file: String = #file, line: Int = #line) -> Self {
            let key = key.with(type)
            dependencies.set(factory, for: key, file: file, line: line)
            return Options(factory, key: key, dependencies: dependencies)
        }
    }
    
    typealias Name = String
}

public extension Dependencies {
    
    private func set(_ factory: Factory, for key: HashKey, file: String = #file, line: Int = #line) {
        registry[key] = factory
    }
    
    func get<Service>(_ type: Service.Type, name: Name? = nil, file: String = #file, line: Int = #line) -> Service {
        guard let service: Service = optional(type, name: name, file: file, line: line) else {
            fatalError("No registration for \(type), registrations: \(registry.keys.map({ String(describing: $0.identifier) }).joined(separator: ", "))")
        }
        return service
    }
    
    func get<Service>(name: Name? = nil) -> Service {
        return get(Service.self, name: name)
    }
    
    func optional<Service>(_ type: Service.Type, name: Name? = nil, file: String = #file, line: Int = #line) -> Service? {
        let key = HashKey(type, name: name)
        guard let factory = registry[key], let instance: Service = factory.get() else {
            return nil
        }
        return instance
    }
    
    func optional<Service>(name: Name? = nil) -> Service? {
        return optional(Service.self, name: name)
    }
    
    @discardableResult
    func register<Service>(name: Name? = nil, _ create: @escaping () -> Service) -> Dependencies.Options<Service> {
        return register(Service.self, name: name, create)
    }
    
    @discardableResult
    func register<Service>(_ type: Service.Type, name: Name? = nil, file: String = #file, line: Int = #line, _ create: @escaping () -> Service) -> Dependencies.Options<Service> {
        let key = HashKey(type, name: name)
        let factory = Factory(create: create, scope: .transient)
        registry[key] = factory
        return Dependencies.Options(factory, key: key, dependencies: self)
    }
    
    func clearCache(id: Scope.CacheID, file: String = #file, line: Int = #line) {
        registry.values.forEach({ factory in
            guard case .cached(let factoryId) = factory.scope, factoryId == id else { return }
            factory.instance = nil
        })
    }
    
    func clearCache(file: String = #file, line: Int = #line) {
        registry.values.forEach({ factory in
            guard case .cached = factory.scope else { return }
            factory.instance = nil
        })
    }
    
    /// Completely reset the registry, meaning all registrations and factories will be cleared.
    func reset(file: String = #file, line: Int = #line) {
        registry = [:]
    }
}

public extension Dependencies {
    
    private func r<T>() -> T {
        return get(T.self)
    }
    
    @discardableResult
    func register<Service>(_ service: Service.Type, _ initializer: @escaping () -> Service) -> Dependencies.Options<Service> {
        return register { initializer() as Service }
    }
    
    @discardableResult
    func register<Service, A>(_ service: Service.Type, _ initializer: @escaping (A) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer(self.r()) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B>(_ service: Service.Type, _ initializer: @escaping ((A, B)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C>(_ service: Service.Type, _ initializer: @escaping ((A, B, C)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T)) -> Service) -> Dependencies.Options<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
}

private class Factory {
    
    private let create: () -> Any
    var instance: Any?
    var scope: Dependencies.Scope
    private let lock = ThreadLock()
    
    init(create: @escaping () -> Any, instance: Any? = nil, scope: Dependencies.Scope) {
        self.create = create
        self.instance = instance
        self.scope = scope
    }
    
    func get<T>(file: String = #file, line: Int = #line) -> T? {
        if scope.shouldCache {
            return lock.performWithLock(id: "\(file.split(separator: "/").last ?? "") - \(line)") {
                if let instance = instance as? T {
                    return instance
                } else {
                    let instance = create() as? T
                    self.instance = instance
                    return instance
                }
            }
        } else {
            return create() as? T
        }
    }
}

private struct HashKey: Hashable {
    
    let identifier: ObjectIdentifier
    let name: String?
    
    init<Service>(_ type: Service.Type, name: Dependencies.Name? = nil) {
        self.identifier = ObjectIdentifier(type)
        self.name = name
    }
    
    func with<Service>(_ type: Service.Type) -> Self {
        return .init(type, name: name)
    }
}
