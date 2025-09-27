const std = @import("std");
const Import = @import("../imports.zig");
const eql = std.mem.eql;

const Token = Import.Token;

const Lexer = @This();

/// The whole file content in a "string"
input: []const u8,
pos: usize,
line: usize = 0,

pub fn init(input: []const u8) Lexer {
    return Lexer{
        .input = input,
        .pos = 0,
        .line = 0,
    };
}

/// Checks if the position is greater or equal to the input length
/// Returns null if the condition checks, otherwise returns a character
pub fn peek(self: *Lexer) ?u8 {
    if (self.pos >= self.input.len) return null;
    return self.input[self.pos];
}

/// Returns the next character in the input
/// Returns null if the next character is null
pub fn advance(self: *Lexer) ?u8 {
    const char = self.peek();
    if (char == null) return null;
    self.pos += 1;
    return char;
}

/// Walks the input and returns a Token
/// How it works:
/// First store the current position of the lexer
/// Then checks if the its current character is valid using the `peek` function
/// Then starts doing checks to find the right token for that input
/// At each check uses a suport character to advance in the case the character after the current is valid and advances the position
/// Then with the initial position and the current one, we slice the input and return a token
/// In a loop, the start position is updated at each loop completed so it `walks` the input
pub fn next(self: *Lexer) Token {
    while (true) {
        const current_char = self.peek() orelse return Token{ .lexeme = "", .token_type = .EOF };

        if (self.skipForExtra(current_char)) {
            _ = self.advance();
            continue;
        }
        break;
    }
    const current_char = self.peek() orelse return Token{ .lexeme = "", .token_type = .EOF };

    const start_pos = self.pos;
    if (self.isAlpha(current_char)) {
        while (true) {
            const char2 = self.peek();
            if (char2 == null or !(self.isAlpha(char2.?) or self.isNumber(char2.?))) break;
            _ = self.advance();
        }

        const lexeme = self.input[start_pos..self.pos];
        const keyword = self.isKeyword(lexeme) orelse {
            return Token{ .token_type = .IDENTIFIER, .lexeme = lexeme };
        };
        return Token{ .token_type = keyword, .lexeme = lexeme };
    }

    if (self.isNumber(current_char)) {
        while (true) {
            const char2 = self.peek();
            if (char2 == null or !(self.isNumber(char2.?))) break;
            _ = self.advance();
        }
        const lexeme = self.input[start_pos..self.pos];
        return Token{ .token_type = .{ .NUMBER = .int }, .lexeme = lexeme };
    }
    if (current_char == '/') {
        _ = self.advance();
        if (current_char != '/') return Token{ .token_type = .UNKNOWN, .lexeme = "" };
        while (true) {
            const char2 = self.peek();
            if (char2 == null or char2.? == '\n') break;
            _ = self.advance();
        }
        const lexeme = self.input[start_pos..self.pos];
        return Token{ .lexeme = lexeme, .token_type = .COMMENT };
    }
    if (self.isOperator(current_char)) {
        while (true) {
            const char2 = self.peek();
            if (char2 == null or !(self.isOperator(char2.?))) break;
            _ = self.advance();
        }

        const operator = self.whichOperator(current_char) orelse return Token{ .lexeme = "", .token_type = .EOF };

        const lexeme = self.input[start_pos..self.pos];
        return Token{ .token_type = operator, .lexeme = lexeme };
    }

    if (self.isPontuation(current_char)) {
        while (true) {
            const char2 = self.peek();
            if (char2 == null or !(self.isPontuation(char2.?))) break;
            _ = self.advance();
        }

        const pontuation = self.whichPontuation(current_char) orelse return Token{ .lexeme = "", .token_type = .EOF };
        const lexeme = self.input[start_pos..self.pos];
        return Token{ .token_type = pontuation, .lexeme = lexeme };
    }
    if (self.isSymbol(current_char)) {
        _ = self.advance();
        const lexeme = self.input[start_pos..self.pos];
        const symbol = self.whichSyboml(current_char) orelse return Token{ .lexeme = "", .token_type = .EOF };

        return Token{ .token_type = symbol, .lexeme = lexeme };
    }

    if (current_char == '"') {
        _ = self.advance();
        while (true) {
            const char2 = self.peek();
            if (char2 == null or char2.? == '"') break;
            _ = self.advance();
        }

        _ = self.advance();

        const lexeme = std.mem.trim(u8, self.input[start_pos..self.pos], "\"");
        return Token{ .lexeme = lexeme, .token_type = .STRING };
    }
    if (current_char == '\'') {
        _ = self.advance();
        while (true) {
            const char2 = self.peek();
            if (char2 == null or char2.? == '\'') break;
            _ = self.advance();
        }

        _ = self.advance();

        const lexeme = std.mem.trim(u8, self.input[start_pos..self.pos], "\'");
        return Token{ .lexeme = lexeme, .token_type = .CHAR };
    }

    _ = self.advance();
    const lexeme = self.input[start_pos..self.pos];
    return Token{ .lexeme = lexeme, .token_type = .UNKNOWN };
}

pub fn skipForExtra(_: *Lexer, char: u8) bool {
    if (char == ' ' or char == '\n' or char == '\r' or char == '\t') {
        return true;
    } else return false;
}

pub fn isAlpha(_: *Lexer, char: u8) bool {
    return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z');
}

pub fn isNumber(_: *Lexer, char: u8) bool {
    return char >= '0' and char <= '9';
}

pub fn isOperator(_: *Lexer, char: u8) bool {
    if (char == '+' or char == '-' or char == '*' or char == '/' or char == '=') {
        return true;
    } else return false;
}

pub fn whichOperator(_: *Lexer, char: u8) ?Token.TokenType {
    switch (char) {
        '+' => return Token.TokenType{ .OPERATOR = .plus },
        '-' => return Token.TokenType{ .OPERATOR = .minus },
        '*' => return Token.TokenType{ .OPERATOR = .times },
        '/' => return Token.TokenType{ .OPERATOR = .divideBy },
        '=' => return Token.TokenType{ .OPERATOR = .equal },
        else => return null,
    }
}

pub fn whichSyboml(_: *Lexer, char: u8) ?Token.TokenType {
    switch (char) {
        '(' => return Token.TokenType{ .SYMBOL = .l_roundBracket },
        ')' => return Token.TokenType{ .SYMBOL = .r_roundBracket },
        '{' => return Token.TokenType{ .SYMBOL = .l_curlyBracket },
        '}' => return Token.TokenType{ .SYMBOL = .r_curlyBracket },
        '[' => return Token.TokenType{ .SYMBOL = .l_bracket },
        ']' => return Token.TokenType{ .SYMBOL = .r_bracket },
        else => return null,
    }
}

pub fn isPontuation(self: *Lexer, char: u8) bool {
    if (char == ';') {
        self.line += 1;
        return true;
    }
    if (char == ',' or char == '?' or char == '!' or char == '.' or char == ':') {
        return true;
    } else return false;
}

pub fn isSymbol(_: *Lexer, char: u8) bool {
    if (char == '{' or
        char == '}' or
        char == '[' or
        char == ']' or
        char == '(' or
        char == ')' or
        char == '$' or
        char == '&' or
        char == '_')
    {
        return true;
    } else return false;
}

pub fn whichPontuation(_: *Lexer, char: u8) ?Token.TokenType {
    switch (char) {
        ';' => return Token.TokenType{ .PUNCTUATION = .semi_colon },
        ',' => return Token.TokenType{ .PUNCTUATION = .comma },
        '?' => return Token.TokenType{ .PUNCTUATION = .interogation },
        '!' => return Token.TokenType{ .PUNCTUATION = .exclamation },
        '.' => return Token.TokenType{ .PUNCTUATION = .dot },
        ':' => return Token.TokenType{ .PUNCTUATION = .colon },
        else => return null,
    }
}

pub fn isKeyword(_: *Lexer, word: []const u8) ?Token.TokenType {
    const allocator = std.heap.page_allocator;
    var keyDict = std.StringArrayHashMap(Token.TokenType).init(allocator);
    defer keyDict.deinit();

    _ = keyDict.put("fn", .{ .KEYWORD = .function_kw }) catch return null;
    _ = keyDict.put("return", .{ .KEYWORD = .return_kw }) catch return null;
    _ = keyDict.put("use", .{ .KEYWORD = .use_kw }) catch return null;
    _ = keyDict.put("as", .{ .KEYWORD = .as_kw }) catch return null;
    _ = keyDict.put("const", .{ .KEYWORD = .const_kw }) catch return null;
    _ = keyDict.put("var", .{ .KEYWORD = .var_kw }) catch return null;
    _ = keyDict.put("class", .{ .KEYWORD = .class_kw }) catch return null;
    _ = keyDict.put("pub", .{ .KEYWORD = .pub_kw }) catch return null;
    _ = keyDict.put("creator", .{ .KEYWORD = .creator_kw }) catch return null;
    _ = keyDict.put("destroyer", .{ .KEYWORD = .destroyer_kw }) catch return null;
    _ = keyDict.put("if", .{ .KEYWORD = .if_kw }) catch return null;
    _ = keyDict.put("else", .{ .KEYWORD = .else_kw }) catch return null;
    _ = keyDict.put("or", .{ .KEYWORD = .or_kw }) catch return null;
    _ = keyDict.put("and", .{ .KEYWORD = .and_kw }) catch return null;
    _ = keyDict.put("for", .{ .KEYWORD = .for_kw }) catch return null;
    _ = keyDict.put("foreach", .{ .KEYWORD = .foreach_kw }) catch return null;
    _ = keyDict.put("while", .{ .KEYWORD = .while_kw }) catch return null;
    _ = keyDict.put("switch", .{ .KEYWORD = .switch_kw }) catch return null;
    _ = keyDict.put("error", .{ .KEYWORD = .error_kw }) catch return null;
    _ = keyDict.put("default", .{ .KEYWORD = .default_kw }) catch return null;
    _ = keyDict.put("try", .{ .KEYWORD = .try_kw }) catch return null;
    _ = keyDict.put("catch", .{ .KEYWORD = .catch_kw }) catch return null;
    return keyDict.get(word);
}

pub fn tokens(self: *Lexer) ![]Token {
    const allocator = std.heap.page_allocator;
    var map = std.array_list.Managed(Token).init(allocator);
    while (true) {
        const token = self.next();
        _ = try map.append(token);
        if (token.token_type == .EOF) break;
    }

    return map.items;
}
