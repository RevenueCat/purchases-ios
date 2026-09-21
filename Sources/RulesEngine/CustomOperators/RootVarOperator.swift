//
//  RootVarOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.rootVar` — like `var`, but reads from the root data scope.
    enum RootVarOperator {

        static func opRootVar(args: Value, vars: Scope) throws -> Value {
            try AccessorOperators.resolveVar(
                args: args,
                lookup: { AccessorOperators.lookupVar(in: vars.root, path: $0) },
                vars: vars,
                operatorName: "rc.rootVar"
            )
        }
    }
}
