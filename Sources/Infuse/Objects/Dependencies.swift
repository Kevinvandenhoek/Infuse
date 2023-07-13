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
    
    func performWithLock<T>(work: () -> T) -> T {
        return syncSafe { work() }
    }
}

public class Dependencies {
    
    public static let shared = Dependencies()
    
    private let lock = ThreadLock()
    
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
        public func scope(_ scope: Dependencies.Scope) -> Self {
            lock.performWithLock {
                factory.scope = scope
            }
            return self
        }
        
        @discardableResult
        public func implements<T>(_ type: T.Type) -> Self {
            let key = key.with(type)
            dependencies.set(factory, for: key)
            return Options(factory, key: key, dependencies: dependencies)
        }
    }
    
    typealias Name = String
}

public extension Dependencies {
    
    private func set(_ factory: Factory, for key: HashKey) {
        lock.performWithLock {
            registry[key] = factory
        }
    }
    
    func get<Service>(_ type: Service.Type, name: Name? = nil) -> Service {
        guard let service: Service = optional(type, name: name) else {
            fatalError("No registration for \(type)")
        }
        return service
    }
    
    func get<Service>(name: Name? = nil) -> Service {
        return get(Service.self, name: name)
    }
    
    func optional<Service>(_ type: Service.Type, name: Name? = nil) -> Service? {
        let key = HashKey(type, name: name)
        return lock.performWithLock {
            guard let factory = registry[key], let instance: Service = factory.get() else {
                return nil
            }
            return instance
        }
    }
    
    func optional<Service>(name: Name? = nil) -> Service? {
        return optional(Service.self, name: name)
    }
    
    @discardableResult
    func register<Service>(name: Name? = nil, _ create: @escaping () -> Service) -> Dependencies.Options<Service> {
        return register(Service.self, name: name, create)
    }
    
    @discardableResult
    func register<Service>(_ type: Service.Type, name: Name? = nil, _ create: @escaping () -> Service) -> Dependencies.Options<Service> {
        let key = HashKey(type, name: name)
        let factory = Factory(create: create, scope: .transient)
        lock.performWithLock {
            registry[key] = factory
        }
        return Dependencies.Options(factory, key: key, dependencies: self)
    }
    
    func clearCache(id: Scope.CacheID) {
        lock.performWithLock {
            registry.values.forEach({ factory in
                guard case .cached(let factoryId) = factory.scope, factoryId == id else { return }
                factory.instance = nil
            })
        }
    }
    
    func clearCache() {
        lock.performWithLock {
            registry.values.forEach({ factory in
                guard case .cached = factory.scope else { return }
                factory.instance = nil
            })
        }
    }
    
    /// Completely reset the registry, meaning all registrations and factories will be cleared.
    func reset() {
        lock.performWithLock {
            registry = [:]
        }
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
    
    init(create: @escaping () -> Any, instance: Any? = nil, scope: Dependencies.Scope) {
        self.create = create
        self.instance = instance
        self.scope = scope
    }
    
    func get<T>() -> T? {
        if scope.shouldCache, let instance = instance as? T { return instance }
        
        let instance = create() as? T
        if scope.shouldCache { self.instance = instance }
        return instance
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
