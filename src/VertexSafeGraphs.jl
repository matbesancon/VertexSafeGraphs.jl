module VertexSafeGraphs

import LightGraphs
const LG = LightGraphs

export VSafeGraph

struct VSafeGraph{T, G<:LG.AbstractGraph{T}, V<:AbstractVector{Int}} <: LG.AbstractGraph{T}
    g::G
    deleted_vertices::V
    VSafeGraph(g::G, v::V) where {T, G<:LG.AbstractGraph{T}, V<:AbstractVector{Int}} = new{T, G, V}(g, v)
end

VSafeGraph(g::G) where {G<:LG.AbstractGraph} = VSafeGraph(g, Vector{Int}())
VSafeGraph(nv::Integer) = VSafeGraph(LG.SimpleGraph(nv))

LG.edges(g::VSafeGraph) = LG.edges(g.g)
LG.edgetype(g::VSafeGraph) = LG.edgetype(g.g)
LG.is_directed(g::VSafeGraph) = LG.is_directed(g.g)
LG.ne(g::VSafeGraph) = LG.ne(g.g)
LG.nv(g::VSafeGraph) = LG.nv(g.g) - length(g.deleted_vertices)
LG.vertices(g::VSafeGraph) = (v for v in LG.vertices(g.g) if !(v in g.deleted_vertices))

LG.outneighbors(g::VSafeGraph, v) = LG.outneighbors(g.g, v)
LG.inneighbors(g::VSafeGraph, v) = LG.inneighbors(g.g, v)
LG.has_vertex(g::VSafeGraph, v) = LG.has_vertex(g.g, v) && !(v in g.deleted_vertices)

LG.has_edge(g::VSafeGraph, e) = LG.has_edge(g.g, e)

LG.add_edge!(g::VSafeGraph, v1, v2) = LG.add_edge!(g.g, v1, v2)
LG.add_vertex!(g::VSafeGraph, v) = LG.add_vertex!(g.g, v)

LG.rem_edge!(g::VSafeGraph, v1, v2) = LG.rem_edge!(g.g, v1, v2)

Base.copy(g::VSafeGraph) = VSafeGraph(copy(g.g), copy(g.deleted_vertices))

function LG.rem_vertex!(g::VSafeGraph, v1)
    if !LG.has_vertex(g, v1) || v1 in g.deleted_vertices
        return false
    end
    for v2 in LG.outneighbors(g, v1)
        LG.rem_edge!(g, v1, v2)
    end
    for v2 in LG.inneighbors(g, v1)
        LG.rem_edge!(g, v2, v1)
    end
    push!(g.deleted_vertices, v1)
    return true
end

end # module
