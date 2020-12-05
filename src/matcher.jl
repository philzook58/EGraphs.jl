# https://www.hpl.hp.com/techreports/2003/HPL-2003-148.pdf
function ematchlist(e::EGraph, t::Array{Union{PatTerm, PatVar}} , v::Array{Id}, sub)
    Channel() do c
        if length(t) == 0
            put!(c, sub)
        else
            for sub1 in ematch(e, t[1], v[1], sub)
                for sub2 in ematchlist(e, t[2:end], v[2:end], sub1)
                    put!(c, sub2)
                end
            end
        end
    end
end
# sub should be a map from pattern variables to Id
function ematch(e::EGraph, t::PatVar, v::Id, sub)
    Channel() do c
        if haskey(sub, t)
            if find_root!(e, sub[t]) == find_root!(e, v)
                put!(c, sub)
            else
                pass
            end
        else
            put!(c,  Base.ImmutableDict(sub, t => find_root!(e, v)))
        end
    end
end

    
function ematch(e::EGraph, t::PatTerm, v::Id, sub)
    Channel() do c
        for n in e.classes[find_root!(e,v)].nodes
            if n.head == t.head
                for sub1 in ematchlist(e, t.args , n.args , sub)
                    put!(c,sub1)
                end
            end
        end
    end
end
    

function instantiate(e::EGraph, p::PatVar , sub)
    sub[p]
end

function instantiate(e::EGraph, p::PatTerm , sub)
    push!( e, Term(p.head, [ instantiate(e,a,sub) for a in p.args ] ))
end



struct Rule
    lhs::Pattern
    rhs::Pattern
end

function rewrite!(e::EGraph, r::Rule)
    matches = []
    EMPTY_DICT2 = Base.ImmutableDict{PatVar, Id}(PatVar(:____),  Id(-1))
    for (n, cls) in e.classes
        for sub in ematch(e, r.lhs, n, EMPTY_DICT2)
            push!( matches, ( instantiate(e, r.lhs ,sub)  , instantiate(e, r.rhs ,sub)))
        end
    end
    for (l,r) in matches
        union!(e,l,r)
    end
    rebuild!(e)
end

