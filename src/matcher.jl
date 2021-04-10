
@auto_hash_equals struct Pattern
    head::Symbol
    args
end

struct PatVar
    name::Symbol
end

pat(e::Symbol) = isuppercase(String(e)[1]) ? PatVar(e) : Pattern(e, [])
pat(e::Expr) = Pattern(e.args[1], pat.(e.args[2:end]) )
macro pat(e) 
    return pat(e)
end

@pat f(g(X), X)

@auto_hash_equals struct ENodePat
    head::Symbol
    args::Vector{Symbol}
end

@auto_hash_equals struct Bind # ExpandEClass, SearchEClass, BindPat
    eclass::Symbol
    enodepat::ENodePat
end

@auto_hash_equals struct CheckClassEq
    eclass1::Symbol
    eclass2::Symbol
end

@auto_hash_equals struct Yield
    yields::Vector{Symbol}
end

function compile_pat(eclass, p::Pattern,ctx)
    a = [gensym() for i in 1:length(p.args) ]
    return vcat(  Bind(eclass, ENodePat(p.head, a  )) , [compile_pat(eclass, p2, ctx) for (eclass , p2) in zip(a, p.args)]...)
end

function compile_pat(eclass, p::PatVar,ctx)
    if haskey(ctx, p.name)
        return CheckClassEq(eclass, ctx[p.name])
    else
        ctx[p.name] = eclass
        return []
    end
end
    
function compile_pat(p)
    ctx = Dict()
    insns = compile_pat(:start, p, ctx)
    
    return vcat(insns, Yield( [values(ctx)...]) ), ctx
end

Code = Union{Expr,Symbol}

function interp_staged(G::Code, insns, ctx, buf::Code) # G could be an argument or a global variable.
    if length(insns) == 0
        return 
    end
    insn = insns[1]
    insns = insns[2:end]
    if insn isa Bind
        enode = gensym(:enode)
        quote
            for $enode in $G[$(ctx[insn.eclass])] # we can store an integer of the eclass.
                if $enode.head == $(QuoteNode(insn.enodepat.head)) && length($enode.args) == $(length(insn.enodepat.args))
                    $(
                        begin
                        for (n,v) in enumerate(insn.enodepat.args)
                            ctx[v] = :($enode.args[$n])
                        end
                        interp_staged(G,  insns, ctx, buf)
                        end
                    )
                end
            end
        end
    elseif insn isa Yield
        quote
            push!( $buf, [ $( [ctx[y] for y in insn.yields]...) ])
        end
    elseif insn isa CheckClassEq
        quote
            if $(ctx[insn.eclass1]) == $(ctx[insn.eclass2])
                $(interp_staged(G, insns, ctx, buf))
            end
        end
    end
end

function interp_staged(insns)
    #buf = gensym(:buf)
    #G = gensym(:G)
    quote
        (G, eclass0) -> begin
            buf = []
            $(interp_staged(:G, insns, Dict{Symbol,Any}([:start => :eclass0]) , :buf))
            return buf
        end
    end
end

function interp_unstaged(G, insns, ctx, buf) 
    if length(insns) == 0
        return 
    end
    insn = insns[1]
    insns = insns[2:end]
    if insn isa Bind
        for enode in G[ctx[insn.eclass]] 
            if enode.head == insn.enodepat.head && length(enode.args) == length(insn.enodepat.args)
                        for (n,v) in enumerate(insn.enodepat.args)
                            ctx[v] = enode.args[n]
                        end
                        interp_unstaged(G,  insns, ctx, buf)
                end
            end
        end
    elseif insn isa Yield
        quote
            push!( buf, [ctx[y] for y in insn.yields])
        end
    elseif insn isa CheckClassEq
        quote
            if ctx[insn.eclass1] == ctx[insn.eclass2]
                interp_unstaged(G, insns, ctx, buf)
            end
        end
    end
end

function interp_unstaged(G, insns, eclass0)
        buf = []
        interp_unstaged(G, insns, Dict{Symbol,Any}([:start => :eclass0]) , buf)
        return buf
end


#=
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

function pat(e::Symbol)
    PatTerm(e, [])
end

function pat( e::Expr )
    if e.head == :call
        if e.args[1] == :~
            PatVar(e.args[2])
        else
            PatTerm(e.args[1],  [  pat(a) for a in e.args[2:end] ] )
        end
    end
end

macro pat(e)
    pat(e)
end

macro rule(e)
    @assert e.args[1] == :(=>) || e.args[1] == :(==)
    Rule( pat(e.args[2]) , pat(e.args[3]) )
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

function prove_eq(e::EGraph, t1::Id, t2::Id , rules)
    for i in 1:3
        if in_same_set(e,t1,t2)
            return true
        end
        for r in rules
            rewrite!(e,r) # i should split this stuff up. We only need to rebuild at the end
        end
    end
    return nothing
end

=#