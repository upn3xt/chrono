const std = @import("std");
const Import = @import("chrono/imports.zig");

const Token = Import.Token;
const Lexer = Import.Lexer;
const Parser = Import.Parser2;
const ASTNode = Import.ASTNode;
const Analyzer = Import.Analyzer;
const Printer = Import.Printer;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("syntaxv1/plain.chro", .{ .mode = .read_only });

    var contentBuf: [1024]u8 = undefined;
    const contentBytes = try file.readAll(&contentBuf);

    const content = contentBuf[0..contentBytes];

    var lexer = Lexer.init(content);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    const tokens = try lexer.tokens();

    // Printer.printTokens(tokens);

    var parser = Parser.init(allocator, tokens);
    const nodes = try parser.ParseTokens();

    // Printer.printAST(nodes);

    std.debug.print("Nodes has length of {}\n", .{nodes.len});

    // const sym = std.StringHashMap(Analyzer.Type).init(allocator);

    // var analyzer = Analyzer.init(nodes, sym);

    // try analyzer.analyzer();
}
