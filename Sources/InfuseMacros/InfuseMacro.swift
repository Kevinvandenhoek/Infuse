import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum StorageBehavior {
    case singleton
    case local
}

private func makeProviderDecl(registrationName: String, instanceName: String, accessModifier: String?, createExpression: ExprSyntax, storage: StorageBehavior) -> DeclSyntax {
    return {
        let accessString: String = {
            if let accessModifier {
                return "\(accessModifier) "
            } else {
                return ""
            }
        }()
        switch storage {
        case .singleton:
            return """
            \(raw: accessString)struct \(raw: registrationName)Provider {
                private static var instance: \(raw: instanceName)?
                private static let lock = ThreadLock()
                \(raw: accessString)static func get() -> \(raw: registrationName) {
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
        case .local:
            return """
            \(raw: accessString)struct \(raw: registrationName)Provider {
                \(raw: accessString)static func get() -> \(raw: registrationName) {
                    return \(createExpression)
                }
            }
            """
        }
    }()
}

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
        

        let storage: StorageBehavior = {
            switch node.arguments?.as(LabeledExprListSyntax.self)?.first(withLabel: "storage")?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.trimmedDescription {
            case "singleton":
                return .singleton
            case "local":
                return .local
            default:
                return .local
            }
        }()
        return [makeProviderDecl(
            registrationName: registrationName,
            instanceName: instanceName,
            accessModifier: accessModifier,
            createExpression: createExpression,
            storage: storage
        )]
    }
}

public struct FreestandingProvidableMacro: DeclarationMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let args = node.as(MacroExpansionExprSyntax.self)?.arguments else {
            throw "No args provided"
        }
        
        let registrationName: String?
        let instanceName: String?
        if let expr = args.first(withLabel: nil)?.expression.as(AsExprSyntax.self) {
            registrationName = expr.type.as(IdentifierTypeSyntax.self)?.name.trimmedDescription
            if let member = expr.expression.as(MemberAccessExprSyntax.self) {
                instanceName = member.base?.as(DeclReferenceExprSyntax.self)?.baseName.trimmedDescription
            } else if let function = expr.expression.as(FunctionCallExprSyntax.self) {
                instanceName = function.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.trimmedDescription
            } else {
                throw "Unsupported arg"
            }
        } else if let expr = args.first(withLabel: nil)?.expression.as(FunctionCallExprSyntax.self) {
            registrationName = expr.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.trimmedDescription
            instanceName = registrationName
        } else if let expr = args.first(withLabel: nil)?.expression.as(MemberAccessExprSyntax.self) {
            registrationName = expr.base?.as(DeclReferenceExprSyntax.self)?.baseName.trimmedDescription
            instanceName = registrationName
        } else {
            throw "Unsupported arg"
        }
        
        let createExpression: ExprSyntax = try {
            if let expr = args.first(withLabel: nil)?.expression {
                return expr
            } else {
                throw "Failed to find create expression"
            }
        }()
        
        guard let registrationName, let instanceName else {
            throw "Missing data"
        }
        
        let storage: StorageBehavior = {
            switch args.as(LabeledExprListSyntax.self)?.first(withLabel: "storage")?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.trimmedDescription {
            case "singleton":
                return .singleton
            case "local":
                return .local
            default:
                return .local
            }
        }()
        
        return [makeProviderDecl(
            registrationName: registrationName,
            instanceName: instanceName,
            accessModifier: "public",
            createExpression: createExpression,
            storage: storage
        )]
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
        ProvidedMacro.self,
        FreestandingProvidableMacro.self
    ]
}

private extension LabeledExprListSyntax {
    
    func first(withLabel label: String?) -> LabeledExprSyntax? {
        return first { element in
            return element.label?.trimmedDescription == label
        }
    }
}
