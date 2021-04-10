module EGraphs

using AutoHashEquals

# Write your package code here.
export IntDisjointMap, find_root, EGraph, congruences, ENode, addenode!, addexpr!, propagate_congruence, @pat,
       Pattern, PatVar, compile_pat, interp_staged, Bind, Yield, CheckClassEq, ENodePat, rebuild!, interp_unstaged

include("intdisjointmap.jl")
include("egraph.jl")
include("matcher.jl")

end
