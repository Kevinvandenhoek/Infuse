import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ProvidableMacro: PeerMacro {
    
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        print(node)
        print(declaration)
        print(context)
        let registrationName: String
        let accessModifier: String
        if let decl = declaration.as(StructDeclSyntax.self) {
            registrationName = decl.name.trimmed.text
            accessModifier = decl.modifiers.first?.name.trimmed.text ?? "internal"
        } else if let decl = declaration.as(ClassDeclSyntax.self) {
            registrationName = decl.name.trimmed.text
            accessModifier = decl.modifiers.first?.name.trimmed.text ?? "internal"
        } else if let decl = declaration.as(EnumDeclSyntax.self) {
            registrationName = decl.name.trimmed.text
            accessModifier = decl.modifiers.first?.name.trimmed.text ?? "internal"
        } else if let decl = declaration.as(ProtocolDeclSyntax.self) {
            registrationName = decl.name.trimmed.text
            accessModifier = decl.modifiers.first?.name.trimmed.text ?? "internal"
        } else {
            throw "Unsupported type"
        }
        let instanceName: String = {
            if let functionExpression = node.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first(withLabel: nil)?.expression.as(FunctionCallExprSyntax.self) {
                    return functionExpression.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.trimmedDescription
            } else if let memberExpression = node.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first(withLabel: nil)?.expression.as(MemberAccessExprSyntax.self) {
                return memberExpression.base?.as(DeclReferenceExprSyntax.self)?.baseName.trimmedDescription
            } else {
                return nil
            }
        }() ?? registrationName
        
        let createExpression: ExprSyntax = {
            if let expression = node.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first(withLabel: nil)?.expression.as(FunctionCallExprSyntax.self) {
                return "\(expression)"
            } else if let expression = node.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first(withLabel: nil)?.expression.as(MemberAccessExprSyntax.self) {
                return "\(expression)"
            } else {
                return "\(raw: instanceName)()"
            }
        }()
        
        let providerDecl: DeclSyntax = try {
            if let storage = node.arguments?.as(LabeledExprListSyntax.self)?.first(withLabel: "storage")?.expression.as(MemberAccessExprSyntax.self) {
                switch storage.declName.baseName.trimmed.text {
                case "singleton":
                    return """
                    \(raw: accessModifier) struct \(raw: registrationName)Provider {
                        private static var instance: \(raw: instanceName)?
                        private static let lock = ThreadLock()
                        \(raw: accessModifier) static func get() -> \(raw: registrationName) {
                            let existing = lock.performWithLock { instance }
                            if let existing {
                                return existing
                            } else {
                                let new = \(createExpression)
                                lock.performWithLock {
                                    instance = new
                                }
                                return new
                            }
                        }
                    }
                    """
                case "local":
                    return """
                    \(raw: accessModifier) struct \(raw: registrationName)Provider {
                        \(raw: accessModifier) static func get() -> \(raw: registrationName) {
                            return \(createExpression)
                        }
                    }
                    """
                default:
                    throw "unknown storage type: \(storage)"
                }
            } else {
                return """
                \(raw: accessModifier) struct \(raw: registrationName)Provider {
                    \(raw: accessModifier) static func get() -> \(raw: registrationName) {
                        return \(createExpression)
                    }
                }
                """
            }
        }()
        
        return [
            providerDecl
        ]
    }
}

public struct ProvidedMacro: ExpressionMacro {
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let name = node.as(MacroExpansionExprSyntax.self)?.arguments.as(LabeledExprListSyntax.self)?.first?.expression.as(MemberAccessExprSyntax.self)?.base?.as(DeclReferenceExprSyntax.self)?.baseName.trimmed.text else {
            throw "Missing argument"
        }
        
        return "\(raw: name)Provider.get()"
    }
}

extension String: Error { }

@main
struct InfusePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProvidableMacro.self,
        ProvidedMacro.self
    ]
}

private extension LabeledExprListSyntax {
    
    func first(withLabel label: String?) -> LabeledExprSyntax? {
        return first { element in
            return element.label?.trimmedDescription == label
        }
    }
}
