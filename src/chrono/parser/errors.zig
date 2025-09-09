pub const ExpectedTokenError = error{ Identifier, NumberLiteral, String, Char, Bool, Operator, Puntuaction, Symbol, Keyword, Unknown, Eof };
pub const ParsingError = error{
    VariableDeclarationFailed,
    VariableReferenceFailed,
    FunctionDeclarationFailed,
    FunctionCallFailed,
};
const UnexpectedTokenError = error{UnexpectedToken};
pub const ParserError = ParsingError || UnexpectedTokenError || ExpectedTokenError;

pub fn errorHandler(err: ParserError) !void {
    switch (err) {
        UnexpectedTokenError => {},
        else => {},
    }
}
