const std = @import("std");
const Token = @import("chrono/token.zig");
const Lexer = @import("chrono/lexer.zig");
const Parser = @import("chrono/parser.zig");
const ASTNode = @import("chrono/ast.zig");
const Analyzer = @import("chrono/analyzer.zig");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("syntaxv1/charsnstrs.chro", .{ .mode = .read_only });

    var contentBuf: [1024]u8 = undefined;
    const contentBytes = try file.readAll(&contentBuf);

    const content = contentBuf[0..contentBytes];

    var lexer = Lexer.init(content);

    // const allocator = std.heap.page_allocator;

    const tokens = try lexer.tokens();

    for (tokens) |value| {
        std.debug.print("[Token]: {s}\t[Type]: {}\n", .{ value.lexeme, value.token_type });
    }
    //
    // var parser = Parser.init(allocator, tokens);
    //
    // const nodes = try parser.ParseTokens();
    //
    // if (nodes != null) {
    //     std.debug.print("Nodes has length of {}\n", .{nodes.?.len});
    // } else {
    //     std.debug.print("Nodes returned null.\n", .{});
    // }
}
