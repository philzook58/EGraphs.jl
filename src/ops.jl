
# returns the canonical Id
find_root!(e::EGraph, id::Id) = Id(DataStructures.find_root!(e.unionfind, id.id))

in_same_set(e::EGraph, t1::Term, t2::Term) = in_same_set(e.unionfind, e.memo[t1].id , e.memo[t2].id)
in_same_set(e::EGraph, t1::Id, t2::Id) = in_same_set(e.unionfind, t1.id,t2.id)

function canonicalize!(e::EGraph, t::Term)
    t.args = [ find_root!(e, a) for a in t.args ]
end

function canonicalize(e::EGraph, t::Term)
    Term( t.head, [ find_root!(e, a) for a in t.args ])
end

function find_class!(e::EGraph, t::Term)  # lookup
    canonicalize!(e, t) #t.args = [ find_root!(e, a) for a in t.args ]  # canonicalize the term
    if haskey(e.memo, t)
        id = e.memo[t]
        return find_root!(e, id)
    else
        return nothing
    end
end

function Base.push!(e::EGraph, t::Term)
    id = find_class!(e,t) # also canonicalizes t
    if id === nothing # term not in egraph. Make new class and put in graph
        id = Id(push!(e.unionfind))
        cls = EClass( [t] , [] )
        for child in t.args # set parent pointers
            push!(e.classes[child].parents,  (t, id))
        end
        e.classes[id] = cls
        e.memo[t] = id
        return id
    else
        return id
    end
end


function Base.union!(e::EGraph, id1::Id, id2::Id)
    id1 = find_root!(e, id1)
    id2 = find_root!(e, id2)
    # An invariant is that the EClass data should always keyed with the root of the union find
    # in the e.classes datastructure
    if id1 != id2 # if not already in same class
        id3 = Id(union!(e.unionfind, id1.id,id2.id)) # perform the union find
        if id3 == id1 # picked id1 as root
            to = id1
            from = id2
        elseif id3 == id2 # picked id2 as root
            to = id2
            from = id1
        else
            @assert false
        end
            
        push!(e.dirty_unions, id3) # id3 will need it's parents processed in rebuild!
        
        # we empty out the e.class[from] and put everything in e.class[to]
        newnodes = Set()
        for t in e.classes[from].nodes
            delete!(e.memo, t) # remove stale term
            canonicalize!(e, t) # update term in place in nodes array
            e.memo[t] = to # now this term is in the to eqauivalence class
            push!(newnodes, t)
        end
        # recanonize all nodes in memo.

        for t in e.classes[to].nodes
            delete!(e.memo, t) # remove stale term
            canonicalize!(e, t) # update term in place in nodes array
            e.memo[t] = to # now this term is in the to eqauivalence class
            push!(newnodes, t)
        end

        e.classes[to].nodes = collect(newnodes)
        println(newnodes)
        
        # merge parents list
        for (p,id) in e.classes[from].parents
            push!(e.classes[to].parents, (p, find_root!(e,id)))
        end
        
        # destroy "from" from e.classes. It's information should now be
        # in e.classes[to] and it should never be accessed.
        delete!(e.classes, from) 
    end 
        
end

function repair!(e::EGraph, id::Id)
    cls = e.classes[id]
    
    #  for every parent, update the hash cons. We need to repair that the term has possibly a wrong id in it
    for (n,(t,t_id)) in enumerate(cls.parents)
        delete!( e.memo, t) # the parent should be updated to use the updated class id
        canonicalize!(e, t) # canonicalize
        #cls.parents[n] = (t,t_id)
        e.memo[t] = find_root!(e, t_id) # replace in hash cons  
    end
    
    # now we need to discover possible new congruence eqaulities in the parent nodes.
    # we do this by building up a parent hash to see if any new terms are generated.
    new_parents = Dict()
    for (t,t_id) in cls.parents
        canonicalize!(e,t) # canonicalize. Unnecessary by the above? Well, no we're performing unions in this loop
        if haskey(new_parents, t)
            union!(e, t_id, new_parents[t])
        end
        new_parents[t] = find_root!(e, t_id)
    end
    e.classes[id].parents = [ (p,id) for (p,id) in new_parents]
end

function rebuild!(e::EGraph)
    while length(e.dirty_unions) > 0
       todo = Set([ find_root!(e,id) for id in e.dirty_unions])
       e.dirty_unions = []
       for id in todo
            repair!(e, id)
        end
    end
end