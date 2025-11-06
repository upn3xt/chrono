# ISSUES

Place to let problems and fixes organized.

## Assign variables to variables

Type mismatch error. What I guess: I need to make sure(at compile time) that the types match when assigning so returns the error early. The error risides in 
the variable declaration error. 

Idea: Use a symbol map

The thing is that I can't modify the node after it has been created and there's some confusion while getting the types.

Update: Still no fix, but need to use the maps to get the object type
