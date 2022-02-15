using Julog
using HerbSWIPL
using Test

#include("swipl_test.jl")

@testset "SWIPL basics" begin
    prolog = Swipl()

    start(prolog)

    clauses = @julog [p(c) <<= true]
    goal = @julog p(X)

    sat, result = swipl_resolve(prolog, goal, clauses)
    @test length(result) == 1

    clauses2 = @julog [
        q(a) <<= true,
        q(b) <<= true,
        q(c) <<= true
    ]

    goal2 = @julog q(X)

    sat, result2 = swipl_resolve(prolog, goal2, clauses2)
    @test length(result2) == 3

    clauses3 = @julog [
        r(a,b) <<= true,
        r(a,c) <<= true
    ]
    goal3 = @julog r(X,Y)

    sat, result = swipl_resolve(prolog, goal3, clauses3)
    @test length(result) == 2

    clauses4 = @julog [
        t(a, f(b)) <<= true,
        t(b, f(c)) <<= true
    ]
    goal = @julog t(X,Y)

    sat, result = swipl_resolve(prolog, goal, clauses4)
    @test length(result) == 2

    
    goal = @julog member(X, [1,2,3,4,5])
    sat, result = swipl_resolve(prolog, goal, Vector{Clause}())
    @test length(result) == 5


    clauses = @julog [
        n(1) <<= true,
        n(15) <<= true
    ]
    goal = @julog n(X)
    sat, result = swipl_resolve(prolog, goal, clauses)

    stop(prolog)
end

@testset "SWIPL with rules" begin
    prolog = Swipl()

    start(prolog)

    clauses = @julog [
        edge(1,2) <<= true,
        edge(2,3) <<= true,
        edge(2,4) <<= true,
        edge(4,5) <<= true,
        path(X,Y) <<= edge(X,Y),
        path(X,Y) <<= edge(X,Z) & path(Z,Y)
    ]

    goal = @julog path(X,Y)
    sat, result = swipl_resolve(prolog, goal, clauses)
    @assert lengtth(result) == 8

    stop(prolog)
end

@testset "SWIPL foreign predicates" begin
    prolog = Swipl()
    start(prolog)

    function hello(term::Const)
        println("Hello $(term)!")
        return (true, Dict{Int64,Term}())
    end

    register_foreign(hello; mode=:det)
    goal = @julog hello(toby)
    sat, result = swipl_resolve(prolog, goal, Vector{Clause}())

    stop(prolog)
end