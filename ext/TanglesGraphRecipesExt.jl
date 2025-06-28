module TanglesGraphRecipesExt

using Tangles
using Plots
using Graphs
using GraphRecipes
import GraphRecipes: graphplot

function GraphRecipes.graphplot(tn::Tangles.AbstractTensorNetwork; node_labels=false, edge_labels=false)

    if !isempty(inds(tn; set=:hyper))
        throw(ArgumentError("hyper indices not supported for visualization yet"))
    end

    tensormap = IdDict(tensor => i for (i, tensor) in enumerate(tensors(tn)))

    g = Graphs.SimpleGraph(length(tensors(tn)))
    
    for i in inds(tn; set=:inner)
        edge_tensors = tensors(tn; intersect=i)

        @assert length(edge_tensors) == 2
        a, b = edge_tensors

        add_edge!(g, tensormap[a], tensormap[b])
    end

    # Add ghost nodes for open indices
    ghostnodes = Int[]
    for index in inds(tn; set=:open)
        add_vertex!(g)
        ghost_node = nv(g)
        push!(ghostnodes, ghost_node)
        for _tensor in tensors(tn; intersect=index)
            add_edge!(g, ghost_node, tensormap[_tensor])
        end
    end

    # Node labels
    nlabels = [string(i) for i in 1:nv(g)]

    # Node colors: ghost nodes in black, others in a color
    ncolors = [i in ghostnodes ? "black" : "orange" for i in 1:nv(g)]

    # Node sizes: ghost nodes small, others based on tensor size
    nsizes = [i in ghostnodes ? 0.01 : 1 for i in 1:nv(g)]

    # Edge labels (optional, e.g. index names)
    elabels = nothing
    elabels = ["" for e in edges(g)]

    
    plt = graphplot(g, #  layout=grid_layout, # spring_layout, # layout=stressmajorize_layout,
        #names=nlabels,
        #nodefillc=ncolors,
        #method=:spring,
        nodesize=0.2,
        node_weights=nsizes,
        #markersize=nsizes,
        curves=false,
        nodeshape=:circle)
        #edgelabel=elabels,

    return plt
end

end
