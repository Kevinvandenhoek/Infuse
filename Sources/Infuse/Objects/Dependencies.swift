//
//  Dependencies.swift
//  
//
//  Created by Kevin van den Hoek on 11/07/2023.
//

import Foundation

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
    }
    
    struct Options<Service> {
        
        private let factory: Factory
        
        fileprivate init(_ factory: Factory) {
            self.factory = factory
        }
        
        @discardableResult
        public func scope(_ scope: Dependencies.Scope) -> Self {
            factory.scope = scope
            return self
        }
    }
    
    typealias Name = String
}

public extension Dependencies {
    
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
        guard let factory = registry[key], let instance: Service = factory.get() else {
            return nil
        }
        return instance
    }
    
    func optional<Service>(name: Name? = nil) -> Service? {
        return optional(Service.self, name: name)
    }
    
    @discardableResult
    func register<Service>(_ create: @escaping () -> Service, name: Name? = nil) -> Dependencies.Options<Service> {
        return register(create, as: Service.self, name: name)
    }
    
    @discardableResult
    func register<Service>(_ create: @escaping () -> Service, as type: Service.Type, name: Name? = nil) -> Dependencies.Options<Service> {
        let key = HashKey(type, name: name)
        let factory = Factory(create: create, scope: .transient)
        registry[key] = factory
        return Dependencies.Options(factory)
    }
    
    @discardableResult
    func register<Service>(_ instance: Service, name: Name? = nil) -> Dependencies.Options<Service> {
        return register(instance, as: Service.self, name: name)
    }
    
    @discardableResult
    func register<Service>(_ instance: Service, as type: Service.Type, name: Name? = nil) -> Dependencies.Options<Service> {
        let key = HashKey(type, name: name)
        let factory = Factory(create: { instance }, instance: instance, scope: .singleton)
        registry[key] = factory
        return Dependencies.Options(factory)
    }
    
    func clearCache(id: Scope.CacheID) {
        registry.values.forEach({ factory in
            guard case .cached(let factoryId) = factory.scope, factoryId == id else { return }
            factory.instance = nil
        })
    }
    
    func clearCache() {
        registry.values.forEach({ factory in
            guard case .cached = factory.scope else { return }
            factory.instance = nil
        })
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
        switch scope {
        case .singleton, .cached:
            if let instance = instance as? T { return instance }
        case .transient:
            break
        }
        
        let instance = create() as? T
        self.instance = instance
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
}
