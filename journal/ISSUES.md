# ISSUES

Place to let problems and fixes organized.

## Assign variables to variables

Type mismatch error. What I guess: I need to make sure(at compile time) that the types match when assigning so returns the error early. The error risides in 
the variable declaration error. 

Idea: Use a symbol map

The thing is that I can't modify the node after it has been created and there's some confusion while getting the types.

Update: Still no fix, but need to use the maps to get the object type

## Assign variables to variables (partial fix)

Got LLVM IR from the assigning a variable to a variable and it's partially working. Why partially? Had to do some tricks to make it work and still needs to be 
a general solution for all of the types. 

## Better errors

There's a need for better errors.

## Assigning variables to variables(mostly fixed)

Now assigning variables to variables is possible. The fix was adding a symbol map to the 
parseVariableDeclaration function in the parser.zig. It was a scope problem because I was 
using a global map and the function one.

Now there's a problem on emitting the IR. I assume there's a problem on the assignment anda fix for it.


## Assigning variables to variables(fixed)

Now is possible to assign variables to variables. The only catch is that somehow it got more instructions that I thought💀. Anyway victory.
