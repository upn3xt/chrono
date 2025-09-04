# Abstract Syntax Tree (AST) Documentation

Chrono's AST struct(**ASTNode**) is located at `../../src/chrono/ast.zig` and
contains two fields: `kind` and `data`. 

The `kind` field is of type **NodeKind** which is a enum containing elements 
like: *VariableDeclaration, VariableReference, NumberLiteral, BinaryOperation
and Assignment*.

The `data` field is a tagged union of type **NodeKind**.

Each element is a srtuct containing information like names, values and 
expressions(which can be a pointer to the **ASTNode**).
