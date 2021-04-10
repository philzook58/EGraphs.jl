using EGraphs
using Test

@testset "Basic EGraph" begin
G = EGraph()
a = addenode!(G, ENode(:a, []))
b = addenode!(G, ENode(:b, []))
#println(G)
union!(G, a, b)
#println(G)
@test addenode!(G, ENode(:a, [])) == 2
@test addenode!(G, ENode(:c, [])) == 3
@test addenode!(G, ENode(:f, [a])) == 4
union!(G, 3, 4)

#= println(G)
for (k,v) in G.eclass
    println(k,v)
end =#
G = EGraph()
a = addenode!(G, ENode(:a, []))
b = addenode!(G, ENode(:b, []))
c = addenode!(G, ENode(:c, []))

fa = addenode!(G, ENode(:f, [a])) 
fb = addenode!(G, ENode(:f, [b])) 
fc = addenode!(G, ENode(:f, [c])) 

union!(G, a, b)
@test congruences(G) == [(fa,fb)]
ffa = addenode!(G, ENode(:f, [fa])) 
ffb = addenode!(G, ENode(:f, [fb])) 




for (x,y) in congruences(G)
    union!(G,x,y)
end

@test congruences(G) == [(ffa,ffb)]

union!(G, a, c)

@test congruences(G) == [(fc,fb), (ffa,ffb)]

for (x,y) in congruences(G)
    union!(G,x,y)
end

@test congruences(G) == []


G = EGraph()
f5a = addexpr!(G, :( f(f(f(f(f(a)))))  ))
f2a = addexpr!(G, :( f(f(a))  ))
@test length(G.eclass) == 6
union!(G , f5a, f2a)
@test find_root(G,f5a) == find_root(G,f2a)
@test length(G.eclass) == 5
f5a = addexpr!(G, :( f(f(f(f(f(a)))))  ))
f2a = addexpr!(G, :( f(f(f(a)))  ))
@test length(G.eclass) == 5

G = EGraph()
f5a = addexpr!(G, :( f(f(f(f(f(a)))))  ))
fa = addexpr!(G, :( f(a)  ))
a = addexpr!(G, :a)
@test length(G.eclass) == 6
union!(G , fa, a)
@test find_root(G,fa) == find_root(G,a)

propagate_congruence(G)
@test length(G.eclass) == 1

G = EGraph()
ffa = addexpr!(G, :( f(f(a))  ))
f5a = addexpr!(G, :( f(f(f(f(f(a)))))  ))
a = addexpr!(G, :a)
@test length(G.eclass) == 6
union!(G , ffa, a)
@test find_root(G,ffa) == find_root(G,a)

propagate_congruence(G)
@test length(G.eclass) == 2



end