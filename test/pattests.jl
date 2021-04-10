using EGraphs
using Test


@testset "Basic PatMacro" begin
    @test (@pat(f)) == Pattern(:f, [])
    @test (@pat(f(X))) == Pattern(:f, [PatVar(:X)])
    @test (@pat(f(g(X),X)) == Pattern(:f, [Pattern(:g, [PatVar(:X)]), PatVar(:X)]))
end



@testset "Basic Compile" begin
    @test compile_pat(@pat f)[1] == [Bind(:start, ENodePat(:f, [])), Yield([])]

    p1, ctx1 = compile_pat(@pat f(X))
    @test p1 == [Bind(:start, ENodePat(:f,  [ctx1[:X]]  )), Yield([ctx1[:X]])]
    
    p1, ctx = compile_pat(@pat f(X, Y))
    @test p1 == [Bind(:start, ENodePat(:f,  [ctx[:X], ctx[:Y] ]  )), 
                 Yield([ctx[:X], ctx[:Y]])]
    @test ctx[:X] != ctx[:Y]
    @test length(ctx) == 2

    p1, ctx = compile_pat(@pat f(X, X))
    x2 = p1[1].enodepat.args[2]
    @test length(ctx) == 1
    @test p1 == [Bind(:start, ENodePat(:f,  [ctx[:X], x2 ]  )), 
                 CheckClassEq( x2 , ctx[:X] ),
                 Yield([ctx[:X]])]

    p1, ctx = compile_pat(@pat f(g(X)))
    g = p1[1].enodepat.args[1]
    @test length(ctx) == 1
    @test p1 == [Bind(:start, ENodePat(:f,  [g ]  )),
                Bind(g, ENodePat(:g,  [ctx[:X] ]  )) ,
                Yield([ctx[:X]])]

end

using MacroTools
@testset "Basic Match" begin
    G = EGraph()
    a = addexpr!(G, :a) 
    b = addexpr!(G, :b) 
    fa = addexpr!(G, :( f(a)  ))
    fb = addexpr!(G, :( f(b)  ))

    p1, ctx1 = compile_pat(@pat f(X))

    println(prettify(interp_staged( p1  )))
    match = eval(interp_staged( p1  ))
    @test match(G, fa) == [ [ a ] ]
    @test match(G, fb) == [ [ b ] ]
    union!(G, fa, fb)
    #println(G)
    @test match(G, fa) == [ [ b ], [ a ]  ]
    union!(G, a, b)
    #println(G)
    #println(congruences(G))
    propagate_congruence(G)
    #println(G)
    #println(congruences(G))
    rebuild!(G) # There is something kind of sick here.
    #println(G)
    a = addexpr!(G, :a)
    @test match(G, fa) == [ [ a ] ]


    p1, ctx = compile_pat(@pat f(g(X)))
    match = eval(interp_staged( p1  ))
    G = EGraph()
    a = addexpr!(G, :a) 
    b = addexpr!(G, :b) 
    fga = addexpr!(G, :( f(g(a))  ))
    fb = addexpr!(G, :( f(b)  ))
    @test match(G,fb) == []
    @test match(G,fga) == [[a]]
    union!(G, fb, fga)
    @test match(G,fb) == [[a]]
    @test match(G,fga) == [[a]]



    p1, ctx = compile_pat(@pat f(X, X))
    #println(prettify(interp_staged( p1  )))
    match = eval(interp_staged( p1  ))
    G = EGraph()
    a = addexpr!(G, :a) 
    b = addexpr!(G, :b) 
    fga = addexpr!(G, :( f(g(a))  ))
    fb = addexpr!(G, :( f(b)  ))
    fab = addexpr!(G, :( f(a,b)  ))
    @test match(G,fab) == []
    faa = addexpr!(G, :( f(a,a)  ))
    @test match(G,faa) == [[a]]
    @test match(G,fab) == []
    union!(G,a,b)
    rebuild!(G)
    #propagate_congruence(G)
    @test match(G,faa) == [[b]]
    @test match(G,fab) == [[b]]



    #println(prettify(interp_staged( p1  )))
end