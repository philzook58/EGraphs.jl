module EGraphs

# Write your package code here.
export EGraph, constant!, term!, rebuild!, find_root!, PatVar, PatTerm, ematch, Id, Rule, rewrite!, graphplot, in_same_set

include("types.jl")
include("ops.jl")
include("utils.jl")
include("matcher.jl")
end
