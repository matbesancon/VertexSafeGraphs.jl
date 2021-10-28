module VertexSafeGraphs

import Graphs

export VSafeGraph

"""
    VSafeGraph{T, G<:Graphs.AbstractGraph{T}}

A `Graphs.AbstractGraph` type maintaining vertex numbering, even after vertex removal.
"""
struct VSafeGraph{T, G<:Graphs.AbstractGraph{T}} <: Graphs.AbstractGraph{T}
    g::G
    deleted_vertices::BitSet
    VSafeGraph(g::G, bs::BitSet) where {T, G<:Graphs.AbstractGraph{T}} = new{T, G}(g, bs)
end

VSafeGraph(g::G) where {G<:Graphs.AbstractGraph} = VSafeGraph(g, BitSet())
VSafeGraph(nv::Integer) = VSafeGraph(Graphs.SimpleGraph(nv))

Graphs.edges(g::VSafeGraph) = Graphs.edges(g.g)
Graphs.edgetype(g::VSafeGraph) = Graphs.edgetype(g.g)

Graphs.is_directed(g::VSafeGraph) = Graphs.is_directed(g.g)
Graphs.is_directed(::Type{VSafeGraph}) = false
Graphs.is_directed(::Type{<:VSafeGraph{T,G}}) where {T, G} = Graphs.is_directed(G)

Graphs.ne(g::VSafeGraph) = Graphs.ne(g.g)
Graphs.nv(g::VSafeGraph) = Graphs.nv(g.g) - length(g.deleted_vertices)
Graphs.vertices(g::VSafeGraph) = (v for v in Graphs.vertices(g.g) if !(v in g.deleted_vertices))

Graphs.has_vertex(g::VSafeGraph, v) = Graphs.has_vertex(g.g, v) && !(v in g.deleted_vertices)

Graphs.has_edge(g::VSafeGraph, src, dst) = Graphs.has_edge(g.g, src, dst)
Graphs.has_edge(g::VSafeGraph, edge::Graphs.AbstractEdge) = Graphs.has_edge(g.g, Graphs.src(edge), Graphs.dst(edge))

Graphs.add_vertex!(g::VSafeGraph) = Graphs.add_vertex!(g.g)

Graphs.rem_edge!(g::VSafeGraph, v1, v2) = Graphs.rem_edge!(g.g, v1, v2)

Base.copy(g::VSafeGraph) = VSafeGraph(copy(g.g), copy(g.deleted_vertices))

function Graphs.outneighbors(g::VSafeGraph, v)
    if !Graphs.has_vertex(g, v)
        throw(ArgumentError("$v is not a valid vertex in graph."))
    end
    ns = Graphs.outneighbors(g.g, v)
    return setdiff(ns, g.deleted_vertices)
end

function Graphs.inneighbors(g::VSafeGraph, v)
    if !Graphs.has_vertex(g, v)
        throw(ArgumentError("$v is not a valid vertex in graph."))
    end
    ns = Graphs.inneighbors(g.g, v)
    return setdiff(ns, g.deleted_vertices)
end

function Graphs.add_edge!(g::VSafeGraph, v1, v2)
    if !Graphs.has_vertex(g, v1) || !Graphs.has_vertex(g, v2)
        return false
    end
    return Graphs.add_edge!(g.g, v1, v2)
end

Graphs.add_edge!(g::VSafeGraph, edge::Graphs.AbstractEdge) = Graphs.add_edge!(g, Graphs.src(edge), Graphs.dst(edge))

function Graphs.rem_vertex!(g::VSafeGraph, v1)
    if !Graphs.has_vertex(g, v1) || v1 in g.deleted_vertices
        return false
    end
    for v2 in Graphs.outneighbors(g, v1)
        Graphs.rem_edge!(g, v1, v2)
    end
    for v2 in Graphs.inneighbors(g, v1)
        Graphs.rem_edge!(g, v2, v1)
    end
    push!(g.deleted_vertices, v1)
    return true
end

end # module
