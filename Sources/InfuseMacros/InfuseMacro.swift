import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ProvidableMacro: PeerMacro {
    
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        print(node)
        print(declaration)
        print(context)
        let instanceName = {
            let name = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(MemberAccessExprSyntax.self)?.base?.as(DeclReferenceExprSyntax.self)?.baseName.trimmed.text
            return name == "Void" ? nil : name
        }()
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
        return [
            """
            \(raw: accessModifier) struct \(raw: registrationName)Provider {
                \(raw: accessModifier) static func get() -> \(raw: registrationName) {
                    return \(raw: instanceName ?? registrationName)()
                }
            }
            """
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
