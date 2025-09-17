const Walker = @This();
const std = @import("std");
const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});

/// Walks through the AST nodes and emits an object
pub fn walk() !void {}

pub fn createMain() !void {}

pub fn createVariable() !void {}

pub fn emitObject() !void {}
