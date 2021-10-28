using VertexSafeGraphs

using Test
import Random

import Graphs

@testset "Graph construction and basic interface" begin
    nv = 20
    g1 = VSafeGraph(nv)
    @test Graphs.nv(g1) == nv
    @test Graphs.nv(g1.g) == nv
    @test Graphs.ne(g1) == 0
    @test Graphs.add_edge!(g1, 1, 2)
    g1_copy = copy(g1)
    @test Graphs.ne(g1) == 1 == Graphs.ne(g1_copy)
    @test Graphs.add_edge!(g1, 1, 3)
    @test Graphs.ne(g1) == 2 == Graphs.ne(g1_copy) + 1
    
    g2_inner = Graphs.complete_graph(nv)
    g2 = VSafeGraph(g2_inner)
    @test Graphs.nv(g2) == Graphs.nv(g2_inner)
    @test Graphs.ne(g2) == Graphs.ne(g2_inner)

    @test all(sort(collect(Graphs.vertices(g2))) .== sort(collect(Graphs.vertices(g2_inner))))

    @test Graphs.has_edge(g2, 1, 2)
    @test Graphs.has_edge(g2, Graphs.SimpleEdge(1, 2))
    @test Graphs.edgetype(g2) == Graphs.edgetype(g2_inner)

    g3 = VSafeGraph(Graphs.complete_digraph(30))
    @test !Graphs.add_edge!(g3, 1, 2) # no possible addition on a complete graph
    @test !Graphs.add_edge!(g3, Graphs.SimpleEdge(1, 2))
    @test Graphs.is_directed(g3)
    @test !Graphs.is_directed(g2)
    @test Graphs.is_directed(typeof(g3))
    @test !Graphs.is_directed(typeof(g2))
    @test !Graphs.is_directed(VSafeGraph)
    @test 15 in Graphs.vertices(g3)
    @test !in(33, Graphs.vertices(g3))
end

@testset "Vertex deletion" begin
    Random.seed!(33)
    nv = 45
    inner = Graphs.complete_graph(nv)
    g = VSafeGraph(inner)
    @test Graphs.ne(inner) == Graphs.ne(g)
    @test Graphs.nv(inner) == Graphs.nv(g)
    @test Graphs.has_vertex(g, 12)
    @test 12 in Graphs.vertices(g)        
    nrm = 0
    for _ in 1:15
        vertex = rand(1:nv)
        removed_ok = Graphs.rem_vertex!(g, vertex)
        if !removed_ok
            continue
        end
        @test !Graphs.has_vertex(g, vertex)
        @test !(vertex in Graphs.vertices(g))        
        nrm += 1
        @test Graphs.nv(inner) == nv
        @test Graphs.nv(g) == nv - nrm
        @test length(g.deleted_vertices) == nrm

        @test Graphs.ne(inner) == Graphs.ne(g)
    end
    @test Graphs.add_vertex!(g)
    @test Graphs.nv(g) == nv - nrm + 1
    @test Graphs.nv(g.g) == nv + 1
end


@testset "Edge addition" begin
    Random.seed!(45)
    nv = 10
    inner = Graphs.complete_graph(nv)
    g = VSafeGraph(inner)
    nea = 0         #number of edges added
    nrv = 0         #number of removed vertices
    neo = Graphs.ne(g)  #original number of edges
    for _ in 1:5
        removed_ok = Graphs.rem_vertex!(g, rand(1:nv))
        if !removed_ok
            continue
        end
        nrv += 1
    end

    ne = length(Graphs.edges(g))   #new number of edges
    for _ in 1:10
        v1 = rand(1:nv)
        v2 = rand(1:nv)
        while v2 == v1
            v2 = rand(1:nv)
        end
        added_ok = Graphs.add_edge!(g, v1, v2)
        if added_ok
            nea += 1
        end
        @test Graphs.ne(g) == ne + nea
	    @test Graphs.nv(g) == nv - nrv
    end
end

@testset "Neighbor sets" begin
    Random.seed!(33)
    nv = 10
    inner = Graphs.complete_graph(nv)
    g = VSafeGraph(inner)
    nrv = 0
    for _ in 1:5
        removed_vertex = rand(1:nv)
        tv = rand(1:nv)
        while !Graphs.has_vertex(g, tv) || tv == removed_vertex
            tv = rand(1:nv)
        end
    	removed_ok = Graphs.rem_vertex!(g, removed_vertex)
        if !removed_ok
            continue
        end
        nrv += 1
        @test_throws ArgumentError Graphs.inneighbors(g, removed_vertex)
        @test_throws ArgumentError Graphs.outneighbors(g, removed_vertex)
        @test !(removed_vertex in Graphs.outneighbors(g, tv))
        @test !(removed_vertex in Graphs.inneighbors(g, tv))
        @test Graphs.nv(g) == nv - nrv
    end
end

@testset "Generic Graphs algorithms work" begin
    nv = 45
    inner = Graphs.complete_graph(nv)
    g = VSafeGraph(inner)
    removed_ok = Graphs.rem_vertex!(g, rand(1:nv))
    @test removed_ok
    # Graphs broken here
    @test_throws BoundsError Graphs.pagerank(g)
    @test_throws BoundsError Graphs.kruskal_mst(g)
end
