const Token = @This();

token_type: TokenType,
lexeme: []const u8,

pub const TokenType = union(enum) {
    IDENTIFIER,
    NUMBER: TNumber,
    STRING,
    CHAR,
    BOOL: TBoolean,
    OPERATOR: TOperator,
    PUNCTUATION: TPuntuaction,
    SYMBOL: TSymbol,
    KEYWORD: TKeyword,
    UNKNOWN,
    EOF,
    COMMENT,
};

pub const TNumber = enum { int, float, double };
pub const TOperator = enum { equal, plus, minus, times, divideBy };
pub const TPuntuaction = enum { dot, colon, semi_colon, interogation, exclamation, comma };
pub const TSymbol = enum { l_roundBracket, l_bracket, l_curlyBracket, r_roundBracket, r_bracket, r_curlyBracket };
pub const TKeyword = enum { function_kw, return_kw, use_kw, as_kw, const_kw, var_kw, class_kw, pub_kw, priv_kw, prot_kw, creator_kw, destroyer_kw, if_kw, else_kw, or_kw, and_kw, for_kw, foreach_kw, while_kw, switch_kw, error_kw, default_kw, try_kw, catch_kw };
pub const TBoolean = enum { t_true, t_false };

const OpPrecedence = enum {
    plus,
    minus,
    divibeBy,
    times,
};
