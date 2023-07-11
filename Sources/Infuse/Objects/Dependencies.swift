//
//  Dependencies.swift
//  
//
//  Created by Kevin van den Hoek on 11/07/2023.
//

import Foundation

public class Dependencies {
    
    public static let shared = Dependencies()
    
    private var registry: [ObjectIdentifier: Factory] = [:]
}

public extension Dependencies {
    
    enum Scope {
        public typealias CacheID = String
        
        case transient
        case singleton
        case cached(id: CacheID?)
    }
}

public extension Dependencies {
    
    func get<Service>(_ type: Service.Type) -> Service {
        let key = ObjectIdentifier(type)
        guard let factory = registry[key] else {
            fatalError("No registration for \(type)")
        }
        return factory.get()
    }
    
    func get<Service>() -> Service {
        return get(Service.self)
    }
    
    func register<Service>(_ create: @escaping () -> Service) -> DependencyOptions<Service> {
        return register(create, as: Service.self)
    }
    
    func register<Service>(_ create: @escaping () -> Service, as type: Service.Type) -> DependencyOptions<Service> {
        let key = ObjectIdentifier(type)
        let factory = Factory(create: create, scope: .transient)
        registry[key] = factory
        return DependencyOptions(factory)
    }
    
    func register<Service>(_ instance: Service) -> DependencyOptions<Service> {
        return register(instance, as: Service.self)
    }
    
    func register<Service>(_ instance: Service, as type: Service.Type) -> DependencyOptions<Service> {
        let key = ObjectIdentifier(type)
        let factory = Factory(create: { instance }, instance: instance, scope: .singleton)
        registry[key] = factory
        return DependencyOptions(factory)
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

public struct DependencyOptions<Service> {
    
    private let factory: Factory
    
    fileprivate init(_ factory: Factory) {
        self.factory = factory
    }
    
    func scope(_ scope: Dependencies.Scope) -> Self {
        factory.scope = scope
        return self
    }
}

public extension Dependencies {
    
    private func r<T>() -> T {
        return get(T.self)
    }
    
    @discardableResult
    func register<Service>(_ service: Service.Type, _ initializer: @escaping () -> Service) -> DependencyOptions<Service> {
        return register { initializer() as Service }
    }
    
    @discardableResult
    func register<Service, A>(_ service: Service.Type, _ initializer: @escaping (A) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer(self.r()) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B>(_ service: Service.Type, _ initializer: @escaping ((A, B)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C>(_ service: Service.Type, _ initializer: @escaping ((A, B, C)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S)) -> Service) -> DependencyOptions<Service> {
        return register {
            return initializer((self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r(), self.r())) as Service
        }
    }
    
    @discardableResult
    func register<Service, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T>(_ service: Service.Type, _ initializer: @escaping ((A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T)) -> Service) -> DependencyOptions<Service> {
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
    
    func get<T>() -> T {
        switch scope {
        case .singleton, .cached:
            if let instance = instance as? T { return instance }
        case .transient:
            break
        }
        
        guard let instance = create() as? T else { fatalError("Factory produced wrong type for \(T.self), produced \(String(describing: create()))") }
        self.instance = instance
        return instance
    }
}
