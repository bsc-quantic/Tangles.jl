using Bijections
using Networks
using UUIDs
using QuantumTags
using DelegatorTraits
using ValSplit

struct GenericLattice
    graph::IncidentNetwork{Networks.Vertex{UUID},Networks.Edge{UUID}}
    sitemap::Bijection{Networks.Vertex{UUID},Site}
    bondmap::Bijection{Networks.Edge{UUID},Bond}
end

function GenericLattice()
    GenericLattice(
        IncidentNetwork{Networks.Vertex{UUID},Networks.Edge{UUID}}(),
        Bijection{Networks.Vertex{UUID},Site}(),
        Bijection{Networks.Edge{UUID},Bond}(),
    )
end

function Base.show(io::IO, g::GenericLattice)
    print(io, "GenericLattice ($(length(g.sitemap)) sites, $(length(g.bondmap)) bonds)")
end

# `Network` interface
DelegatorTraits.DelegatorTrait(::Networks.Network, ::GenericLattice) = DelegatorTraits.DelegateToField{:graph}()

Networks.vertex_at(g::GenericLattice, _site) = g.sitemap(_site)
Networks.edge_at(g::GenericLattice, _bond) = g.bondmap(_bond)

# `Lattice` interface
DelegatorTraits.ImplementorTrait(::Tangles.Lattice, ::GenericLattice) = DelegatorTraits.Implements()

Tangles.all_sites(g::GenericLattice) = collect(values(g.sitemap))
Tangles.all_bonds(g::GenericLattice) = collect(values(g.bondmap))
Tangles.all_sites_iter(g::GenericLattice) = values(g.sitemap)
Tangles.all_bonds_iter(g::GenericLattice) = values(g.bondmap)

Tangles.hassite(g::GenericLattice, _site) = hasvalue(g.sitemap, _site)
Tangles.hasbond(g::GenericLattice, _bond) = hasvalue(g.bondmap, _bond)
Tangles.nsites(g::GenericLattice) = length(g.sitemap)
Tangles.nbonds(g::GenericLattice) = length(g.bondmap)

Tangles.site_at(g::GenericLattice, v::Networks.Vertex) = g.sitemap[v]
Tangles.bond_at(g::GenericLattice, e::Networks.Edge) = g.bondmap[e]

function Tangles.setsite!(g::GenericLattice, _site)
    hassite(g, _site) && throw(ArgumentError("$site already in the lattice"))
    v = Networks.Vertex(uuid4())
    addvertex!(g.graph, v)
    g.sitemap[v] = _site
    return g
end

function Tangles.setbond!(g::GenericLattice, _bond)
    hasbond(g, _bond) && throw(ArgumentError("$bond already in the lattice"))
    e = Networks.Edge(uuid4())
    addedge!(g.graph, e)
    _sites = QuantumTags.sites(_bond)
    _vs = [vertex_at(g, _site) for _site in _sites]
    for v in _vs
        Networks.link!(g.graph, v, e)
    end
    g.bondmap[e] = _bond
    return g
end

# predefined constructors
# NOTE dynamic-dispatch due to the `Val`-dispatch, but it's ok since will be called direclty by the user on a high level
GenericLattice(kind::Symbol, args...; kwargs...) = GenericLattice(Val(kind), args...; kwargs...)

"""
    GenericLattice(:chain, n; periodic=false)

Create a chain lattice with `n` sites.

!!! warning

    It fails for `periodic=true` and `n <= 2`.
"""
function GenericLattice(::Val{:chain}, n; periodic=false)
    lattice = GenericLattice()
    for i in 1:n
        setsite!(lattice, site"$i")
    end

    for i in 1:(n - 1)
        setbond!(lattice, bond"$i - $(i + 1)")
    end

    if periodic
        setbond!(lattice, bond"1-$n")
    end

    return lattice
end

"""
    GenericLattice(:rectangular, nrows, ncols; periodic=false)

Create a rectangular lattice with `nrows` rows and `ncols` columns.

!!! warning

    It fails for `periodic=true` and `nrows, ncols <= 2`.
"""
function GenericLattice(::Val{:rectangular}, nrows, ncols; periodic=false)
    lattice = GenericLattice()
    for row in 1:nrows, col in 1:ncols
        setsite!(lattice, site"$row,$col")
    end

    for row in 1:nrows, col in 1:(ncols - 1)
        setbond!(lattice, bond"($row,$col) - ($row,$(col + 1))")
    end

    for row in 1:(nrows - 1), col in 1:ncols
        setbond!(lattice, bond"($row,$col) - ($(row + 1),$col)")
    end

    if periodic
        for row in 1:nrows
            setbond!(lattice, bond"($row,1) - ($row,$ncols)")
        end

        for col in 1:ncols
            setbond!(lattice, bond"(1,$col) - ($nrows,$col)")
        end
    end

    return lattice
end

"""
    GenericLattice(:lieb, ncellrows, ncellcols)

Create a Lieb lattice with `ncellrows` cell rows and `ncellcols` cell columns.
"""
function GenericLattice(::Val{:lieb}, ncellrows, ncellcols)
    lattice = GenericLattice()
    nrows, ncols = 1 .+ 2 .* (ncellrows, ncellcols)

    # add vertices
    for row in 1:nrows, col in 1:ncols
        # skip holes
        row % 2 == 0 && col % 2 == 0 && continue
        setsite!(lattice, site"$row,$col")
    end

    # add horizontal edges
    for row in 1:2:nrows, col in 1:(ncols - 1)
        setbond!(lattice, bond"$(row,col) - $(row, col + 1)")
    end

    # add vertical edges
    for row in 1:(nrows - 1), col in 1:2:ncols
        setbond!(lattice, bond"$(row,col) - $(row + 1, col)")
    end

    return lattice
end
