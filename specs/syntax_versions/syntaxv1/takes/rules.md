# Rules

Some rules for chrono about its syntax 

# Declaration

const → constants
var → mutable variables

const x: type = value;
var y = SomeClass();

# Imports

use → importing modules

use Module/Library as var_name; 
    ex:
        use chrono.net as net; 

# Functions

fn name() type {

}

fn name() type => print("something") or return value_type

fn name() !?*type → {

    ! → might return an error 
    ? → might return null 
    * → returns a pointer
}

# Classes 

pub/priv/prot class Name {

    pub/priv/prot field1: type,

    pub/priv/prot fn privFunc() type{

    }
    
    /// Custom constructor 
    creator init(){
        // ...
    }

    creator custom_constructor2(args){

    }

    destroyer custom_destructor() {
        
    }
}

# Arguments/Options

(something, .{}) → .{} is where arguments go 


# Conditionals 

if(condition) |capture| {
    //code...
}
else if(condition) |capture|{
    //code...
}
else {
    //code ..
}


keywords:

- or
- and 

NOTE: indentation with one code line also work 

# Atributes 

@Atribute(.{})


# Loops

for(array, 0..) |elem, i|{

}

foreach(elem in array){

}

while(condition){

}

# Errors 

const ErrorSet = error {
    error1,
    error2
};

const fail: type| ErrorSet = try invalidFunction();

const catch_fail = invalidFunction() catch |capture| {
    return capture;
};

const fail_switch = invalidFunction() catch |e| {
    switch(e){
        .error1 => {},
        .error2 => {},
        default => {},
    }
};

const fail_errorswitch = invalidFunction() errorswitch {
    .error1 => {},
    .error2 => {},
    default => return;
} → maybe?


# Arrays 

const array: []type = {elem1, elem2};





# AI takes 







# Chrono Language: Design Summary (So Far)

## Core Philosophy

- **Backend-Focused:** Chrono targets backend development, emphasizing safety, clear syntax, and practical features for scalable, maintainable systems.
- **Modern Syntax:** The language draws inspiration from Zig, C#, and modern C++, focusing on clarity, minimalism, and consistency.

## Syntax Foundations

- **Declarations:**  
  - `const` for immutable variables  
  - `var` for mutables  
  - Explicit type annotations

- **Imports:**  
  - `use module as alias;` for importing and aliasing modules

- **Functions:**  
  - Block (`fn name() type { ... }`) and concise (`fn name() type => expr`) forms  
  - Return type annotations with `!`, `?`, and `*` for error, nullable, and pointer types

- **Classes:**  
  - Dedicated `class Name { ... }` syntax  
  - Supports access modifiers (`pub`, `priv`, `prot`) for fields and functions

- **Conditionals & Loops:**  
  - Standard `if`, `else if`, `else` with optional variable capture  
  - Loop options: indexed `for`, `foreach`, and `while`

- **Attributes:**  
  - Inspired by C#, using syntax like  
    `@Route("api", .{ .method = .PUT, })`  
  - Attributes take grouped arguments with the same `. {}` convention as functions

- **Errors:**  
  - Explicit error sets and propagation (`!` in signatures, `catch`/`errorswitch` handling)  
  - No exceptions—errors are returned and handled explicitly

- **Arrays:**  
  - Literal syntax: `const arr: []Type = {elem1, elem2};`

## RAII and Resource Safety

- **C++-Style RAII Core:**  
  - Resource acquisition and release tied to object lifetime  
  - Deterministic destructors (`~ClassName()` or similar), called on scope exit

- **Surpassing C++:**  
  - Less bloat—sensible defaults for copy/move (opt-in for complex resources)  
  - No manual memory management required; run cleanup even on errors
  - Built-in pointer/resource types can cover unique/shared ownership without verbose syntax

- **No Borrow Checker:**  
  - No ownership/borrowing complexity—RAII ensures safe cleanup deterministically

- **Consistent & Minimal:**  
  - Constructor and destructor syntax is explicit, clear, and ergonomic  
  - Integrates naturally with error handling; errors during construction are returned, not thrown

## Error Handling

- **Explicit Returns:**  
  - Functions indicate error possibility with `!` and return descriptive error sets

- **Pattern Matching:**  
  - Catch and handle errors using robust, expressive switch/catch constructs
  - No exceptions: errors never bypass destructors

## Expressive Attributes

- **Uniform Grouped Parameters:**  
  - Use Zig-like `. {}` style for all named parameters (functions, attributes, constructors)

- **Flexible Metadata:**  
  - Attributes can be extended for routing, serialization, or other backend needs

## Suggestions Incorporated

- Simplified member copying/moving (no custom copy constructors unless needed)
- Clear, minimal syntax for ownership/resource management
- Consistent argument and attribute grouping
- Scoped resource management, even for mutexes and interfaces
- Construction/destruction flows are predictable and safe

## Development Roadmap (Agreed Priorities)

- **Type System Definition:** Full specification for types, generics, conversions, and resource semantics
- **Standard Library:** Core data structures, I/O, error utilities, and backend primitives
- **Tooling:** Parser, type checker, package manager, and (optionally) REPL/playground
- **Backend Essentials:** Built-in concurrency/networking, strong attribute/metadata system
- **Documentation:** Examples, idioms, and tutorials highlighting best practices

This summary captures the consensus and the core design directions for Chrono to serve as a modern, productive, and safe backend language—combining the best of modern static languages, explicit resource and error handling, and minimal, readable syntax.
