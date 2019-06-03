using VertexSafeGraphs

using Test
import Random

import LightGraphs
const LG = LightGraphs

@testset "Graph construction and basic interface" begin
    nv = 20
    g1 = VSafeGraph(nv)
    @test LG.nv(g1) == nv
    @test LG.nv(g1.g) == nv
    @test LG.ne(g1) == 0
    @test LG.add_edge!(g1, 1, 2)
    g1_copy = copy(g1)
    @test LG.ne(g1) == 1 == LG.ne(g1_copy)
    @test LG.add_edge!(g1, 1, 3)
    @test LG.ne(g1) == 2 == LG.ne(g1_copy) + 1
    
    g2_inner = LG.CompleteGraph(nv)
    g2 = VSafeGraph(g2_inner)
    @test LG.nv(g2) == LG.nv(g2_inner)
    @test LG.ne(g2) == LG.ne(g2_inner)

    @test all(sort(collect(LG.vertices(g2))) .== sort(collect(LG.vertices(g2_inner))))

    @test LG.has_edge(g2, 1, 2)
    @test LG.has_edge(g2, LG.SimpleEdge(1, 2))
    @test LG.edgetype(g2) == LG.edgetype(g2_inner)

    g3 = VSafeGraph(LG.CompleteDiGraph(30))
    @test !LG.add_edge!(g3, 1, 2) # no possible addition on a complete graph
    @test !LG.add_edge!(g3, LG.SimpleEdge(1, 2))
    @test LG.is_directed(g3)
    @test !LG.is_directed(g2)
    @test LG.is_directed(typeof(g3))
    @test !LG.is_directed(typeof(g2))
    @test !LG.is_directed(VSafeGraph)
end

@testset "Vertex deletion" begin
    Random.seed!(33)
    nv = 45
    inner = LG.CompleteGraph(nv)
    g = VSafeGraph(inner)
    @test LG.ne(inner) == LG.ne(g)
    @test LG.nv(inner) == LG.nv(g)
    nrm = 0
    for _ in 1:15
        removed_ok = LG.rem_vertex!(g, rand(1:nv))
        if !removed_ok
            continue
        end
        nrm += 1
        @test LG.nv(inner) == nv
        @test LG.nv(g) == nv - nrm
        @test length(g.deleted_vertices) == nrm

        @test LG.ne(inner) == LG.ne(g)
    end
    @test LG.add_vertex!(g)
    @test LG.nv(g) == nv - nrm + 1
    @test LG.nv(g.g) == nv + 1
end


@testset "Edge addition" begin
    Random.seed!(45)
    nv = 10
    inner = LG.CompleteGraph(nv)
    g = VSafeGraph(inner)
    nea = 0         #number of edges added
    nrv = 0         #number of removed vertices
    neo = LG.ne(g)  #original number of edges
    for _ in 1:5
        removed_ok = LG.rem_vertex!(g, rand(1:nv))
        if !removed_ok
            continue
        end
        nrv += 1
    end

    ne = length(LG.edges(g))   #new number of edges
    for _ in 1:10
        v1 = rand(1:nv)
        v2 = rand(1:nv)
        while v2 == v1
            v2 = rand(1:nv)
        end
        added_ok = LG.add_edge!(g, v1, v2)
        if added_ok
            nea += 1
        end
        @test LG.ne(g) == ne + nea
	    @test LG.nv(g) == nv - nrv
    end
end

@testset "Neighbor sets" begin
    Random.seed!(99)
    nv = 10
    inner = LG.CompleteGraph(nv)
    g = VSafeGraph(inner)
    nrv = 0
    for _ in 1:5
        rv = rand(1:nv)
        tv = rand(1:nv)
        while !LG.has_vertex(g, tv)
            tv = rand(1:nv)
        end
	removed_ok = LG.rem_vertex!(g, rv)
        if !removed_ok
            continue
        end
        nrv += 1
        @test_throws ArgumentError LG.inneighbors(g, rv)
        @test_throws ArgumentError LG.outneighbors(g, rv)
        @test !(rv in LG.outneighbors(g, tv))
        @test !(rv in LG.inneighbors(g, tv))
        @test LG.nv(g) == nv - nrv
    end
end



@testset "Generic LG algorithms work" begin
    nv = 45
    inner = LG.CompleteGraph(nv)
    g = VSafeGraph(inner)
    removed_ok = LG.rem_vertex!(g, rand(1:nv))
    @test removed_ok
    # LG broken here
    @test_throws BoundsError LG.pagerank(g)
    @test_throws BoundsError LG.kruskal_mst(g)
end
