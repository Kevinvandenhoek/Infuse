// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: suffixed(Provider))
public macro Providable<T>(_ value: T = (), storage: StorageBehavior = .local) = #externalMacro(module: "InfuseMacros", type: "ProvidableMacro")

@freestanding(expression)
public macro provided<T>(_ type: T.Type) -> T = #externalMacro(module: "InfuseMacros", type: "ProvidedMacro")

@freestanding(declaration, names: arbitrary)
public macro providable<T>(_ value: T, storage: StorageBehavior = .local) = #externalMacro(module: "InfuseMacros", type: "FreestandingProvidableMacro")


public enum StorageBehavior {
    case singleton
    case local
}
