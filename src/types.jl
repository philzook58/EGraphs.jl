struct Id
    id::Int64
end

using AutoHashEquals
@auto_hash_equals mutable struct Term
    head::Symbol
    args::Array{Id}
end

mutable struct EClass
    nodes::Array{Term}
    parents::Array{Tuple{Term,Id}}
end

using DataStructures

mutable struct EGraph
    unionfind::IntDisjointSets
    memo::Dict{Term,Id} # int32 UInt32?
    classes::Dict{Id,EClass} # Use array?
    dirty_unions::Array{Id}
end

# Build an empty EGraph
function EGraph()
    EGraph(IntDisjointSets(0), Dict(), Dict(), [])
end

