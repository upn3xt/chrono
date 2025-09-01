const std = @import("std");
const Token = @import("chrono/token.zig");
const Lexer = @import("chrono/lexer.zig");
const Parser = @import("chrono/parser.zig");
const ASTNode = @import("chrono/ast.zig");
const print = std.debug.print;
const Analyzer = @import("chrono/analyzer.zig");
const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});

pub fn main() !void {

    // TASK: MAKE SOME CHRONO CODE COMPILE
    //
    // var file = try std.fs.cwd().openFile("syntaxv1/operations.chro", .{ .mode = .read_only });
    //
    // var contentBuf: [1024]u8 = undefined;
    // const contentBytes = try file.readAll(&contentBuf);
    //
    // const content = contentBuf[0..contentBytes];
    //
    var lexer = Lexer.init("const y = 20;");

    const allocator = std.heap.page_allocator;

    const tokens = try lexer.tokens();

    // tokenPrinter(tokens);

    // std.debug.print("Last token type: {}\n", .{tokens[tokens.len - 1]});
    // std.debug.print("Tokens size:{}\n\n", .{tokens.len});

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.ParseTokens();

    if (nodes != null) {
        std.debug.print("Nodes has length of {}\n", .{nodes.?.len});
    } else {
        std.debug.print("Nodes returned null.\n", .{});
    }

    var syms = std.StringHashMap(Analyzer.Type).init(allocator);
    try Analyzer.analyzeVariableDeclaration(&syms, nodes.?[0].?);

    const context = llvm.LLVMContextCreate();
    const module = llvm.LLVMModuleCreateWithName("chronos");
    const builder = llvm.LLVMCreateBuilderInContext(context);

    createMainWithVariable(module, context);
    //
    // // 2. Create an integer type and constant
    // const int32_type = llvm.LLVMInt32TypeInContext(context);
    // const value_10 = llvm.LLVMConstInt(int32_type, 10, 0);
    //
    // // 3. Create a global variable named 'x'
    // const global_x = llvm.LLVMAddGlobal(module, int32_type, "x");
    // llvm.LLVMSetInitializer(global_x, value_10);
    // llvm.LLVMSetGlobalConstant(global_x, 1);

    try emitObjectFile(module, "output.o");
    print("Object ready!\n", .{});

    // 5. Clean up (if necessary)
    llvm.LLVMDisposeBuilder(builder);
    llvm.LLVMDisposeModule(module);
    llvm.LLVMContextDispose(context);
}

fn tokenPrinter(tokens: []Token) void {
    for (tokens, 0..) |t, i| {
        std.debug.print("[TOKEN]: {s}\t[INDEX]: {}\t\t[TYPE]: {}\n", .{ t.lexeme, i, t.token_type });
    }
}

pub fn emitObjectFile(
    module: llvm.LLVMModuleRef,
    output_path: [*:0]const u8,
) !void {
    var errorx: [*c]u8 = null;

    // Initialize native target for code generation
    if (llvm.LLVMInitializeNativeTarget() != 0) {
        print("Failed to initialize native target", .{});
        return error.TargetError;
    }
    if (llvm.LLVMInitializeNativeAsmPrinter() != 0) {
        print("Failed to initialize ASM printer", .{});
        return error.ASMPrinterError;
    }
    if (llvm.LLVMInitializeNativeAsmParser() != 0) {
        print("Failed to initialize ASM parser", .{});
        return error.ASMParserError;
    }
    var target: llvm.LLVMTargetRef = undefined;

    // Get target triple for host
    const target_triple = llvm.LLVMGetDefaultTargetTriple();

    // Lookup target by triple
    const ret = llvm.LLVMGetTargetFromTriple(target_triple, &target, &errorx);
    if (ret != 0) {
        print("Failed to get target for triple", .{});
        return error.TripleTargetError;
    }

    // Create target machine
    const cpu = "generic";
    const features = "";
    const opt_level = llvm.LLVMCodeGenLevelDefault;
    const reloc_mode = llvm.LLVMRelocDefault;
    const code_model = llvm.LLVMCodeModelDefault;

    const target_machine = llvm.LLVMCreateTargetMachine(
        target,
        target_triple,
        cpu,
        features,
        opt_level,
        reloc_mode,
        code_model,
    );

    // Set module target triple and data layout
    llvm.LLVMSetTarget(module, target_triple);
    const data_layout_ref = llvm.LLVMCreateTargetDataLayout(target_machine);
    // const data_layout_str = llvm.LLVMGetDataLayoutStr(data_layout_ref); // returns [*c]const u8
    // llvm.LLVMSetDataLayout(module, data_layout_str);
    // llvm.LLVMSetDataLayout(module, data_layout_str);

    // Emit object file
    if (llvm.LLVMTargetMachineEmitToFile(
        target_machine,
        module,
        output_path,
        llvm.LLVMObjectFile,
        &errorx,
    ) != 0) {
        print("Failed to emit object file", .{});
        return error.EmitObjectFileError;
    }

    // Cleanup
    llvm.LLVMDisposeTargetData(data_layout_ref);
    llvm.LLVMDisposeTargetMachine(target_machine);
}
pub fn createMainWithVariable(module: llvm.LLVMModuleRef, context: llvm.LLVMContextRef) void {
    const i32_type = llvm.LLVMInt32TypeInContext(context);
    const func_type = llvm.LLVMFunctionType(i32_type, null, 0, 0);
    const main_func = llvm.LLVMAddFunction(module, "main", func_type);
    llvm.LLVMSetFunctionCallConv(main_func, llvm.LLVMCCallConv);

    const entry_bb = llvm.LLVMAppendBasicBlock(main_func, "entry");
    const builder = llvm.LLVMCreateBuilderInContext(context);
    defer llvm.LLVMDisposeBuilder(builder);

    llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);

    // Allocate variable 'x'
    const var_x_ptr = llvm.LLVMBuildAlloca(builder, i32_type, "x");

    // Initialize 'x' to 10
    const const_10 = llvm.LLVMConstInt(i32_type, 10, 0);
    _ = llvm.LLVMBuildStore(builder, const_10, var_x_ptr);

    // Return 0 from main
    const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);
    _ = llvm.LLVMBuildRet(builder, ret_val);
}
