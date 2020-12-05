function constant!(e::EGraph, x::Symbol)
    t = Term(x, [])
    push!(e, t)
end

term!(e::EGraph, f::Symbol) = (args...) -> begin
  t = Term(f, collect(args))
  push!(e,  t)
end


using LightGraphs
using GraphPlot
using Colors

function graph(e::EGraph) 
    nverts = length(e.memo)
    g = SimpleDiGraph(nverts)
    vertmap = Dict([ t => n for (n, (t, id)) in enumerate(e.memo)])
    #=for (id, cls) in e.classes
        for t1 in cls.nodes
            for (t2,_) in cls.parents
                add_edge!(g, vertmap[t2], vertmap[t1])
            end
        end
    end =#
    for (n,(t,id)) in enumerate(e.memo)
        for n2 in t.args
            for t2 in e.classes[n2].nodes
                add_edge!(g, n, vertmap[t2])
            end
        end
    end
    nodelabel = [ t.head for (t, id) in e.memo]
    classmap = Dict([ (id,n)  for (n,id) in enumerate(Set([ id.id for (t, id) in e.memo]))])
    nodecolor = [classmap[id.id] for (t, id) in e.memo]
    
    return g, nodelabel, nodecolor
end

function graphplot(e::EGraph) 
    g, nodelabel,nodecolor = graph(e)


    # Generate n maximally distinguishable colors in LCHab space.
    nodefillc = distinguishable_colors(maximum(nodecolor), colorant"blue")
    gplot(g, nodelabel=nodelabel, nodefillc=nodefillc[nodecolor])
end