// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: suffixed(Provider))
public macro Providable<T>(_ type: T.Type = Void.self) = #externalMacro(module: "InfuseMacros", type: "ProvidableMacro")

@freestanding(expression)
public macro provided<T>(_ type: T.Type) -> T = #externalMacro(module: "InfuseMacros", type: "ProvidedMacro")
