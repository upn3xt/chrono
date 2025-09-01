# Chrono Development Journal

This journal is were all of the next changes, decisions and achievements will be written.

## Chrono redesign 2025-08-26

Chrono so far was designed to be kind of a superset of zig and kind of a dsl language. But I was wrong for thinking that way. The longer I used zig and 
saw what is becoming I realized that chrono won't be following the same path, as well being domain specific would put a label on it. And I don't want that.

As the creator of the chrono, I need to make the next changes:

* Give chrono the liberty to be a general purpose language 

* Create a new design for it (in terms of syntax, nothing much, just so it's no ultra zig-coded/ imitation)

* Make the framework system decentrilized, meaning that the language will only have official: compiler and stdlib. For library, packages and frameworks,
they'll only be marked as trusted and/or third-party.

And other things will give chrono a new identity as: a flexible language with a self-sufficient stdlib.

And so the development will go like:


* Variable declaration, assignment and reference

* Main entry point

* Functions

* if/else

* for/while

* namespacing

* release version 0

* other language features 

* release version 0.2

* make stdlib 

* release version 1

* evolve from there


My focus now is the first point. I want to get some code gen in it and see the assembly generated. Then is, tokenize, parse, analyze, generate, geek, repeat.

## Chrono specs and split up

Today I've talked with some people and they've made me realize the following:

- Find a sweet spot between precision and ergonomics
- Make a language spec to allow the existance of other compilers for the chrono language.
- LLVM is harder than I thought but it's cool and got some output from it(not in the compiler tho)


With that, the next language changes won't happen in this repository. Rather, in a separate repository for all of the spec of the language. Will be working on 
the speculation repository then while also learning how to mess with LLVM. At the end the compiler will(likely) be re-writen(again XD) from scratch based on 
the language speculation and having an idea of how to work with llvm. The goal will be to output some text like hello world in it.


## Fuck that and lets code!

Fuck the specs! I want to code! Today I have a very crappy AI generated form of output! My first every llvm object file. clang linked it and made it executable
and returned 0!

Ofc this need heavy improvement and research but that's a huge step! The moment I grasp this and know how to transverse ts, chrono programs will be become a 
reality!

I'm saving this progress for sure!!
