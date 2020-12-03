using EGraphs
using Documenter

makedocs(;
    modules=[EGraphs],
    authors="Philip Zucer",
    repo="https://github.com/philzook58/EGraphs.jl/blob/{commit}{path}#L{line}",
    sitename="EGraphs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://philzook58.github.io/EGraphs.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/philzook58/EGraphs.jl",
)
