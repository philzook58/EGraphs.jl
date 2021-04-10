using EGraphs
using Test
#=
Write invariant checking functions

every node in EClass find_root! is the EClass

=#

@testset "IntDisjointMap" begin
    G = IntDisjointMap(+)
    push!(G, 1)
    @test G.parents == [-1]
    @test G.values == [1]
    push!(G,14)
    @test G.parents == [-1, -1]
    @test G.values == [1, 14]
    @test G[1] == 1
    @test G[2] == 14
    union!(G,1,2)
    @test G.parents == [2,-2]
    @test G.values == [nothing, 15]
    @test G[1] == 15
    @test G[2] == 15
    push!(G, 4)
    @test find_root(G,1) == 2
    @test find_root(G,2) == 2
    @test find_root(G,3) == 3
    union!(G,1,3)
    @test G[3] == 19
    @test find_root(G,3) == 2
    @test find_root(G,1) == 2
    @test G.parents == [2,-3,2]

    G[3] = 42
    @test G[2] == 42

    G = IntDisjointMap(+)
    push!(G, 42)
    push!(G, 13)
    @test G[1] == 42
    @test G[2] == 13
    union!(G, 1, 2)
    @test G[1] == 55
    @test G[2] == 55


end

include("egraphtest.jl")
