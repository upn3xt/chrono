pub const TokenError = error{ Identifier, NumberLiteral, String, Char, Bool, Operator, Puntuaction, Symbol, Keyword, Unknown, Eof };
pub const ExpectedTokenError = error{TokenError};
pub const UnexpectedTokenError = error{TokenError};
pub const ParsingError = error{
    VariableDeclarationFailed,
    VariableReferenceFailed,
    FunctionDeclarationFailed,
    FunctionCallFailed,
};

pub const ParserError = ParsingError || UnexpectedTokenError || ExpectedTokenError;
