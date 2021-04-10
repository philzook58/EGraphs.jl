struct IntDisjointMap
    parents::Vector{Int64}
    values::Vector{Any}
    reason_ind::Vector{Int64}
    reasons
    merge_fun
end

IntDisjointMap(merge_fun) = IntDisjointMap(Vector{Int64}[], [], [], [], merge_fun)

function Base.length(x::IntDisjointMap)
    acc = 0
    for i in x.parents
        if i < 0
            acc += 1
        end
    end
    return acc
end

function Base.push!(x::IntDisjointMap, v) 
    push!(x.parents, -1)
    push!(x.reason_ind, -1)
    push!(x.values, v)
    return Base.length(x.parents)
end

function find_root(x::IntDisjointMap, i::Int64)
    while x.parents[i] >= 0 # choice here. I suspect >= is best
        i = x.parents[i]
    end
    return i
end

Base.getindex(x::IntDisjointMap, i::Int64) = x.values[find_root(x,i)]
Base.setindex!(x::IntDisjointMap, v, i::Int64) = x.values[find_root(x,i)] = v


function Base.union!(x::IntDisjointMap, i::Int64, j::Int64, reason=:assert)
    pi = find_root(x, i)
    pj = find_root(x, j)
    if pi != pj
        isize = -x.parents[pi]
        jsize = -x.parents[pj]
        if isize > jsize # swap to make size of i less than j
            i, j = j, i
            pi, pj = pj, pi
            isize, jsize = jsize, isize
        end
        x.parents[pj] -= isize # increase new size of pj
        x.values[pj] = x.merge_fun(x.values[pj], x.values[pi])
        x.values[pi] = nothing # clear out unused storage
        x.parents[pi] = pj

        push!(x.reasons, (i,j,reason))
        x.reason_ind[pi] = length(x.reasons)
    end
    return pj
end

#= No. No normalizing unless we're duplicating parents
function normalize!(x::IntDisjointMap)
    for i in length(x)
        pi = find_root(x, i)
        if pi != i
            x.parents[i] = pi
        end
    end
end 
=#


function Base.iterate(x::IntDisjointMap, state=1)
    while state <= length(x.parents)
        if x.parents[state] < 0
            return ((state, x.values[state]) , state + 1)
        end
        state += 1
    end
    return nothing
end

function ancestors(x::IntDisjointMap, i::Int64)
    a = [i]
    while x.parents[i] >= 0
        i = x.parents[i]
        push!(a, i)
    end
    return a
end

function explain(x::IntDisjointMap, i::Int64, j::Int64 )
    stack =   [(i,j)]
    reasons = []
    while length(stack) > 0
        (i,j) = pop!(stack)

        if i == j
            continue
        end
        @assert find_root(x,i) == find_root(x,j)
        ai = ancestors(x, i)
        aj = ancestors(x, j)

        #=
        For lca computation 4 cases.
        1. i = j - already dealt with above
        2. lca(i,j) = i
        3. lca(i,j) = j
        4. lca(i,j) != i != j so we can subtract 1 from indices.
        =#
        if i ∈ aj
            lca = i
            pi = i
            pj = aj[findfirst(q -> q == i, aj) - 1]
        elseif j ∈ ai
            lca = j
            pi = ai[findfirst(q -> q == j, ai) - 1]
            pj = j
        else
            lcaind = findfirst(q -> q ∈ aj, ai)
            lca = ai[lcaind]
            pi = ai[lcaind - 1]
            pj = aj[findfirst(q -> q ∈ ai , aj)]
        end

        if x.reason_ind[pi] > x.reason_ind[pj] # swap to make pj the newest reason
            i,j = j,i
            pi,pj = pj, pi
        end

        (a,b,reason) = x.reasons[x.reason_ind[pj]]
        push!(reasons, (a,b,reason))
        push!(stack, (i,b) )
        push!(stack, (j,a) )
    end
    return reasons
end