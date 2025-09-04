# Tokenizer Documentation

Chrono's tokenizer starts at `../../src/chrono/token.zig` with the main struct
being **Token**.

This struct contains two fields: `token_type` and `lexeme`. The first one is of 
type **TokenType** which is a tagged union and the second one is a **[]const u8**.

TokenType contains generic token types such as: *indetifiers, number, operator
punctuation, symbol, keyword, unknow and EOF*.

The Token struct is mainly used on `../../src/chrono/lexer.zig`, on the **Lexer** 
struct.

The Lexer struct contains two fields: `input` and `pos`. The chrono file 
content (e.g `file.chro`) is passed as a slice and we walk through it using 
`pos` to create the **tokens**. This action is performed by **next()** function.

Next walks through the input returning tokens of the **Token** and the 
**tokens()** function loops through the tokens genereted until it hits the 
EOF *token type* and appends them to a **ArrayList(Token)**.

<!-- 
NOTE: EOF NEEDS TO BE INCLUDED TO THE LIST FOR THE NEXT STAGE → **Parsing**. 
-->

The functions **next() and tokens()** are the most used for sure, but there are 
other helper functions that ease the checks, allowing for a more consize code 
and readability.

<!--
TODO: Make useful comments
-->
