import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(InfuseMacros)
import InfuseMacros

let testMacros: [String: Macro.Type] = [
    "Providable": ProvidableMacro.self,
    "provided": ProvidedMacro.self,
    "providable": FreestandingProvidableMacro.self
]
#endif

final class InfuseTests: XCTestCase {
    func test_providableMacro_withSpecifiedType_shouldProvideSpecifiedType() throws {
        #if canImport(InfuseMacros)
        assertMacroExpansion(
            """
            @Providable(SomeService())
            public protocol SomeWorker { }
            
            struct SomeService: SomeWorker { }
            """,
            expandedSource: """
            public protocol SomeWorker { }
            
            public struct SomeWorkerProvider {
                public static func get() -> SomeWorker {
                    return SomeService()
                }
            }
            
            struct SomeService: SomeWorker { }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_providableMacro_withoutSpecifiedType_shouldProvideAttachedType() throws {
        #if canImport(InfuseMacros)
        assertMacroExpansion(
            """
            @Providable
            struct SomeService { }
            """,
            expandedSource: """
            struct SomeService { }
            
            internal struct SomeServiceProvider {
                internal static func get() -> SomeService {
                    return SomeService()
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_providedMacro_shouldResolve() throws {
        #if canImport(InfuseMacros)
        assertMacroExpansion(
            """
            @Providable(SomeService.shared)
            protocol SomeWorker { }
            
            struct SomeService: SomeWorker {
                static let shared = SomeService()
            }
            
            let someWorker = #provided(SomeWorker.self)
            """,
            expandedSource: """
            protocol SomeWorker { }
            
            internal struct SomeWorkerProvider {
                internal static func get() -> SomeWorker {
                    return SomeService.shared
                }
            }
            
            struct SomeService: SomeWorker {
                static let shared = SomeService()
            }
            
            let someWorker = SomeWorkerProvider.get()
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_providableMacro_withSingletonStorage_shouldCreateProviderWithStorage() throws {
        #if canImport(InfuseMacros)
        assertMacroExpansion(
            """
            @Providable(storage: .singleton)
            struct SomeService { }
            """,
            expandedSource: """
            struct SomeService { }

            internal struct SomeServiceProvider {
                private static var instance: SomeService?
                private static let lock = ThreadLock()
                internal static func get() -> SomeService {
                    let existing = lock.performWithLock {
                        instance
                    }
                    if let existing {
                        return existing
                    } else {
                        let new = SomeService()
                        lock.performWithLock {
                            instance = new
                        }
                        return new
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_freestandingProvidableMacro_withSingletonStorage_shouldCreateProviderWithStorage() throws {
        #if canImport(InfuseMacros)
        assertMacroExpansion(
            """
            public struct SomeService {
                static let shared = SomeService()
            }
            #providable(SomeService.shared, storage: .singleton)
            """,
            expandedSource: """
            public struct SomeService {
                static let shared = SomeService()
            }
            public struct SomeServiceProvider {
                private static var instance: SomeService?
                private static let lock = ThreadLock()
                public static func get() -> SomeService {
                    let existing = lock.performWithLock {
                        instance
                    }
                    if let existing {
                        return existing
                    } else {
                        let new = SomeService.shared
                        lock.performWithLock {
                            instance = new
                        }
                        return new
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
