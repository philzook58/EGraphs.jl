using EGraphs
using Test
#=
Write invariant checking functions

every node in EClass find_root! is the EClass

=#

in_right_class(e::EGraph) = all(   all( find_root!(e,e.memo[n]) == k for n in cls.nodes)  for (k,cls) in e.classes )
memo_canonical(e::EGraph) = all(   all( find_root!(e,a) == id for a in n.args)  for (n,id) in e.memo )

@testset "Atomic equivalence" begin
    # Write your tests here.
    e = EGraphs.EGraph()
    a = constant!(e, :a)
    @test length(e.classes) == 1
    a = constant!(e, :a)
    @test length(e.classes) == 1
    b = constant!(e, :b)
    @test length(e.classes) == 2
    c = constant!(e, :c)
    @test length(e.classes) == 3
    union!(e, a, b)
    @test length(e.classes) == 2
    union!(e, a, c)
    @test length(e.classes) == 1

end

@testset "Simple congruence" begin
    e = EGraphs.EGraph()
    a = constant!(e, :a)
    f = term!(e, :f)
    apply(n, f, x) = n == 0 ? x : apply(n-1,f,f(x))

    union!(e, a, apply(6,f,a))
    union!(e, a, apply(9,f,a))
    println(e.memo)
    # @test memo_canonical(e) # yeah. the parents still need to be fixed right? And that's ok?
    rebuild!(e)
    println(e.memo)
    println(e.classes)
    println(find_root!(e, Id(6)))
    @test in_right_class(e)
    @test length(e.classes) == 3
    @test length(e.memo) == 4

    union!(e, a, apply(11,f,a))
    rebuild!(e)
    @test in_right_class(e)
    @test memo_canonical(e)
    @test length(e.classes) == 1
    @test length(e.memo) == 2

end


EMPTY_DICT2 = Base.ImmutableDict{PatVar, Id}(PatVar(:____),  Id(-1))

@testset "Simple match" begin
    e = EGraphs.EGraph()
    a = constant!(e, :a)
    f = term!(e, :f)
    p = PatVar

    for sub in EGraphs.ematch(e , PatVar(:x) , a,  EMPTY_DICT2 )
        #println(sub)
    end
    #f(f(f(f(a))))
    for sub in EGraphs.ematch(e , PatTerm(:f, [PatVar(:x)]) , f(f(f(a))),  EMPTY_DICT2 )
        #println(sub)
    end
    union!(e, a, f(a))
    rebuild!(e)
    @test length(e.classes) == 1
    #@test length(e.memo) == 2
    println(e.memo) # what? This dict has two entries for the same thing? Could this be my mutation problem rearing it's head?
    @test length(e.classes[Id(1)].parents) == 1
    f(f(f(a)))
    println(e.memo)
    println(e.classes) # The class has duplicates in it's node array
    for sub in EGraphs.ematch(e , PatTerm(:f, [PatVar(:x)]) , f(f(f(a))),  EMPTY_DICT2 )
        println(sub)
    end

end


@testset "Assoc1" begin
    e = EGraphs.EGraph()
    a = constant!(e, :a)
    b = constant!(e, :b)
    c = constant!(e, :c)
    f = term!(e, :f)
    
    f(f(a,b),c)
    graphplot(e)
    x = PatVar(:x)
    y = PatVar(:y)
    z = PatVar(:z)
    pf = (x,y) -> PatTerm(:f, [x,y])
    r = Rule(  pf(pf(x,y),z) ,     pf(x,pf(y,z)) )

    @test !in_same_set(e,     f(f(a,b),c),     f(a, f(b,c)))
    rewrite!(e, r)
    @test in_same_set(e,     f(f(a,b),c),     f(a, f(b,c)))
    rewrite!(e, r) # shouldn't do anything extra
    graphplot(e)

end

@testset "Assoc2" begin
    e = EGraphs.EGraph()
    a = constant!(e, :a)
    b = constant!(e, :b)
    c = constant!(e, :c)
    d = constant!(e, :d)
    #h = constant!(e, :h)
    f = term!(e, :f)
    
    t1 = f(f(f(a,b),c),d)
    t2 = f(a,f(b,f(c,d)))
    graphplot(e)
    x = PatVar(:x)
    y = PatVar(:y)
    z = PatVar(:z)
    pf = (x,y) -> PatTerm(:f, [x,y])
    r = Rule(  pf(pf(x,y),z) ,     pf(x,pf(y,z)) )
    
    @test !in_same_set(e,    t1, t2)
    rewrite!(e, r)
    graphplot(e)
    @test ! in_same_set(e,     t1, t2)
    rewrite!(e, r)
    @test in_same_set(e,     t1, t2)
    graphplot(e)

end

#=

So we should also write the extraction functions to get good terms out.





=#

@testset "Cat1" begin
    e = EGraphs.EGraph()
    a = constant!(e, :a)
    #b = constant!(e, :b)
    #c = constant!(e, :c)
    f = constant!(e, :f)

    id = term!(e, :id) # allow optionally to specify the arity
    comp = term!(e, :∘)
    swap = term!(e, :σ)
    

    
    pid = ob -> PatTerm(:id, [ob])
    pcomp = (f,g) -> PatTerm(:∘, [f,g])
    x = PatVar(:x)
    pf = PatVar(:f)

    r1 = Rule( pcomp( pf, pid(x) ), pf)
    r2 = Rule( pcomp( pid(x), pf ), pf)
    r3 = Rule( pf, pcomp( pf, pid(x) ))
    comp(f,id(a))
    graphplot(e)
    rewrite!(e, r1)
    graphplot(e)
    rewrite!(e, r3)
    graphplot(e)


end