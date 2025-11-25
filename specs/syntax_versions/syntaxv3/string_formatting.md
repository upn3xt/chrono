# String formatting for chrono

```ts
const str = $"Hello { "world" }";

printf(str);


// or

const str2 = "One: %d, Two: %d";

printf(str2, 1, 2);
```

The code above represents the possible ways of making string formatting native in the language. The first option turns out to be more elegant and possibly make the syntax look cooler 
and reduce work rather than having to do %something. Also the `$` symbol would only make sense for strings, as using it in another context may raise an error, so one symbol for one case.


The issue has been already written and it's only a matter of making it real now.
