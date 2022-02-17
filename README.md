# HerbSWIPL.jl

HerbSWIPL is a Julia wrapper around [SWI Prolog](https://www.swi-prolog.org/) allow you to fully utilise Prolog from your Julia programs.

HerbSWIPL is part of a larger project, [Herb](https://github.com/Herb-AI), aiming to provide a programmable toolkit for program synthesis and induction.


# Installation

First install [SWIPL](https://www.swi-prolog.org/) and make sure its shared library (`libswipl.dylib` on OSX, `libswipl.so` on Linux) is available through `DYLD_LIBRARY_PATH` env variable.

Enter the package manager by pressing `]` in Julia REPL, then run:
```
add <link to this git repository>
```


# Features

 - Prolog-like syntax
 - Performant wrapper built around SWIPL's foreign function interface
 - Access to the majority of SWIPL's capabilities
 - Add Julia functions as Prolog predicates


# Usage

HerbSWIPL.jl is built around [Julog](https://github.com/ztangent/Julog.jl), a Julia implementation of a Prolog engine. 
HerbSWIPL.jl uses Julog to represent logic programs and follows it interface, making it easy to switch between engines.


Start the Prolog engine
```julia
prolog = Swipl()
start(prolog)
```

Represent a knowledge base/logic program with the `@julog` macro
```julia
clauses = @julog [
  ancestor(sakyamuni, bodhidharma) <<= true,
  teacher(bodhidharma, huike) <<= true,
  teacher(huike, sengcan) <<= true,
  teacher(sengcan, daoxin) <<= true,
  teacher(daoxin, hongren) <<= true,
  teacher(hongren, huineng) <<= true,
  ancestor(A, B) <<= teacher(A, B),
  ancestor(A, C) <<= teacher(B, C) & ancestor(A, B),
  grandteacher(A, C) <<= teacher(A, B) & teacher(B, C)
]
```

Query SWIPL via `resolve` function
```julia
# Query: Who are the grandteachers of whom?
julia> goals = @julog [grandteacher(X, Y)];
julia> sat, subst = resolve(prolog, goals, clauses);
julia> sat
true
julia> subst
4-element Array{Any,1}:
  {Y => sengcan, X => bodhidharma}
  {Y => daoxin, X => huike}
  {Y => hongren, X => sengcan}
  {Y => huineng, X => daoxin}
```

You can specify the number of solutions with ther `mode` keyword:
 - `:all`: return all solutions
 - `:any`: return a single solution
 - `:max`: return the number of solutions specified through the `max_solutions` keyword
 ```julia
julia> sat, subst = resolve(prolog, goals, clauses; mode=:all);
julia> sat, subst = resolve(prolog, goals, clauses; mode=:max, max_solution=5);
 ```



 By default, `resolve` will assert the provided clauses before running the query and retract them upon query completion.
 You can prevent `resolve` from retracting everything through the `keep` option: `keep=true`.


 By default, HerbSWIPL returns lists in the pair format.
 However, this turns out to be extremely inefficient for long lists.
 A significantly more efficient alternative is to return answers as Julia Vectors.
 For this reason, HerbSWIPL allows you to choose the format of the lists through the `lists` option:
  - `:julia` returns lists as Julia Vector
  - `:julog` returns lists in the pair format
  ```
  sat, res = swipl_resolve(prolog, goal, clauses; lists=:julia)
  ```


# Julia functions as Prolog predicates

HerbSWIPL.jl supports converting Julia functions to Prolog predicates
```julia
julia> prolog = Swipl()
julia> start(prolog)

julia> function hello(term::Const)
    println("Hello $(term)!")
    return (true, Dict{Int64,Term}())
end

julia> register_foreign(hello; mode=:det)
julia> goal = @julog hello(toby)
julia> sat, result = swipl_resolve(prolog, goal, Vector{Clause}())
Hello toby!
julia> stop(prolog)
```

Julia foreign functions need to obey the following specification:
 - they should expect Julog terms as arguments
 - they should return a tuple where:
   - the first element is a `Bool` indicating whether the call has succeeded 
   - the second element is a `Dict{Int,Term}` mapping the arguments of the function to the terms they should unify to upon completing this call. The terms should be represented as Julog terms.
   
For instance, consider a function `function married(so1::Const, so2::Const)` which maps to the predicate `married(X,Y)` which is true if `X` is married to `Y`:
```julia
function married(so1::Const, so2::Const)
    if so1.name == :toby
        return (true, Dict{Int,Term}(2 => Const(:mary)))
    else
        return (false, Dict{Int,Term}())
    end
end
```
In case the first argument is `toby` the funtion returns `(true, Dict{Int,Term}(2 => Const(:mary)))`. 
`true` indicates that the query succeeded, while `Dict{Int,Term}(2 => Const(:mary))` indicates that the second argument of the function `so2` should be unified with `mary` (represented as `Const(:mary)` in Julog).
In all other cases, the function returns  `(false, Dict{Int,Term}())`, indicating that the query has not succeeded, and no unifications need to be performed (empty `Dict`).
Note that the arguments are 1-indexed.

 **Note:** only the deterministic foreign functions are currently supported. 