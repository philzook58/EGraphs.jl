@auto_hash_equals struct ENode
    head::Symbol
    args::Vector{Int64}
    # hash. This is a good trick?
end

struct EGraph
    eclass::IntDisjointMap
    memo::Dict{ENode, Int64}
    orig_enode::Vector{ENode}
end

EGraph() = EGraph( IntDisjointMap(union)  , Dict{ENode,Int64}(), ENode[])

#ENode(head, args...) = ENode(head, args)
canonize(G::EGraph, f::ENode) = ENode(f.head, [find_root(G.eclass, a) for a in f.args])

find_root(G::EGraph, i::Int64) = find_root(G.eclass, i)

function addenode!(G::EGraph, f::ENode)
    f = canonize(G,f)
    if haskey(G.memo, f)
        return G.memo[f]
    else
        id = push!(G.eclass, [f])
        push!(G.orig_enode, f)
        G.memo[f] = id
        return id
    end
end

addexpr!(G::EGraph, f::Symbol) = addenode!(G, ENode(f,[]))
function addexpr!(G::EGraph, f::Expr)
    @assert f.head == :call
    addenode!(G,  ENode(f.args[1], [ addexpr!(G,a) for a in f.args[2:end] ]  ))
end

function Base.union!(G::EGraph, f::Int64, g::Int64)
    id = union!(G.eclass, f, g)
    eclass = ENode[]
    for enode in G.eclass[id] 
        # more deeply introspecting, we only need to update one half of the list? What about the parents?
        # Any key that has The old class needs updating.
        # If we're fixing it all up at rebuild, why even bother with the memo table? I guess it saves some strife.
        # I'm not sure.
        delete!(G.memo, enode) # should we even bother with delete? It isn't wrong to ignore
        enode = canonize(G, enode) # should canonize return whether it did naything or not?
        G.memo[enode] = id
        push!(eclass, enode)
    end
    G.eclass[id] = eclass
end

function rebuild!(G::EGraph)
    for (id1, eclass) in G.eclass
        G.eclass[id1] = collect(Set([canonize( G, enode ) for enode in eclass]))
    end
end

Base.getindex(x::EGraph, i::Int64) = x.eclass[i]
Base.setindex!(x::EGraph, v, i::Int64) = x.eclass[i] = v

# Hmm. Congurence closure detection reuiqres a double loop. No.
function congruences(G::EGraph)
    buf = Tuple{Int64,Int64}[] 
    for (id1, eclass) in G.eclass #alternatively iterate over memo
        for enode in eclass
            cnode = canonize(G,enode)
            if haskey(G.memo, cnode)
                id2 = G.memo[cnode]
                if id1 != id2
                    push!(buf, (id1,id2))
                end
            end
        end
    end
    return buf
end

function propagate_congruence(G::EGraph)
    cong = congruences(G)
    while length(cong) > 0
        for (i,j) in cong
            union!(G,i,j)
        end
        cong = congruences(G)
    end
end



struct Congruence
    enode1
    enode2
end

function explain(e::EGraph, i::Int64, j::Int64)
    stack = [(i,j)]
    reasons = Dict()
    while length(stack) > 0
        (i, j) = pop!(stack)
        if i == j
            continue 
        end
        # sort for memo table
        i, j = i < j ? (i,j) : (j,i)
        if haskey(reasons, (i,j))
            continue
        end

        reasons_ij = explain(e.eclass, i, j)
        for (_,_,reason) in reasons2
            if reason isa Congruence
                for (i,j) in zip(reason.enode1.args, reason.enode2.args)
                    push!(stack, (i,j))
                end
            end
        end
        reasons[(i,j)] = reason_ij
    end
end