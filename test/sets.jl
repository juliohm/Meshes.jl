@testset "Sets" begin
  @testset "GeometrySet" begin
    s = Segment(point(0, 0), point(1, 1))
    t = Triangle(point(0, 0), point(1, 0), point(0, 1))
    p = PolyArea(point.([(0, 0), (1, 0), (1, 1), (0, 1)]))
    gset = GeometrySet([s, t, p])
    @test Meshes.crs(gset) <: Cartesian{NoDatum}
    @test Meshes.lentype(gset) == ℳ
    @test [centroid(gset, i) for i in 1:3] == point.([(1 / 2, 1 / 2), (1 / 3, 1 / 3), (1 / 2, 1 / 2)])

    s = Segment(point(0, 0), point(1, 1))
    t = Triangle(point(0, 0), point(1, 0), point(0, 1))
    geoms = [s, t]
    gset1 = GeometrySet(geoms)
    gset2 = GeometrySet(g for g in geoms)
    @test gset1 == gset2
    @test parent(gset1) === geoms

    # make sure that eltype is inferred properly
    # https://github.com/JuliaGeometry/Meshes.jl/issues/643
    geoms = Vector{Segment}()
    push!(geoms, Segment(point(0, 0), point(1, 0)))
    push!(geoms, Segment(point(1, 0), point(1, 1)))
    push!(geoms, Segment(point(1, 1), point(0, 0)))
    gset = GeometrySet(geoms)
    @test eltype(gset) <: Segment{2}

    # conversion
    grid = cartgrid(10, 10)
    gset = convert(GeometrySet, grid)
    @test gset isa GeometrySet
    @test nelements(gset) == 100
    @test eltype(gset) <: Quadrangle
  end

  @testset "PointSet" begin
    pset = PointSet(randpoint1(100))
    @test embeddim(pset) == 1
    @test Meshes.crs(pset) <: Cartesian{NoDatum}
    @test Meshes.lentype(pset) === ℳ
    @test nelements(pset) == 100
    @test eltype(pset) <: Point{1}

    pset = PointSet(randpoint2(100))
    @test embeddim(pset) == 2
    @test Meshes.crs(pset) <: Cartesian{NoDatum}
    @test Meshes.lentype(pset) === ℳ
    @test nelements(pset) == 100
    @test eltype(pset) <: Point{2}

    pset = PointSet(randpoint3(100))
    @test embeddim(pset) == 3
    @test Meshes.crs(pset) <: Cartesian{NoDatum}
    @test Meshes.lentype(pset) === ℳ
    @test nelements(pset) == 100
    @test eltype(pset) <: Point{3}

    pset1 = PointSet([point(1, 2, 3), point(4, 5, 6)])
    pset2 = PointSet(point(1, 2, 3), point(4, 5, 6))
    pset3 = PointSet([T.((1, 2, 3)), T.((4, 5, 6))])
    pset4 = PointSet(T.((1, 2, 3)), T.((4, 5, 6)))
    pset5 = PointSet(T[1 4; 2 5; 3 6])
    @test pset1 == pset2 == pset3 == pset4 == pset5
    for pset in [pset1, pset2, pset3, pset4, pset5]
      @test embeddim(pset) == 3
      @test Meshes.lentype(pset) === ℳ
      @test nelements(pset) == 2
      @test pset[1] == point(1, 2, 3)
      @test pset[2] == point(4, 5, 6)
    end

    pset = PointSet(point.([(0, 0), (1, 0), (0, 1)]))
    @test centroid(pset) == point(1 / 3, 1 / 3)

    pset = PointSet(point.([(1, 0), (0, 1)]))
    @test nelements(pset) == 2
    @test centroid(pset, 1) == point(1, 0)
    @test centroid(pset, 2) == point(0, 1)

    pset = PointSet(point.([(0, 0), (1, 0), (0, 1)]))
    @test measure(pset) == zero(T) * u"m"

    # constructor with iterator
    points = point.([(1, 0), (0, 1)])
    pset1 = PointSet(points)
    pset2 = PointSet(p for p in points)
    @test pset1 == pset2

    # datum propagation
    cs = Cartesian{WGS84Latest}.([T.((0, 0)), T.((1, 0)), T.((0, 1))])
    pset = PointSet(Point.(cs))
    @test datum(Meshes.crs(centroid(pset))) === WGS84Latest

    pset = PointSet(point.([(1, 0), (0, 1)]))
    @test sprint(show, pset) == "2 PointSet"
    if T == Float32
      @test sprint(show, MIME"text/plain"(), pset) == """
      2 PointSet
      ├─ Point(x: 1.0f0 m, y: 0.0f0 m)
      └─ Point(x: 0.0f0 m, y: 1.0f0 m)"""
    elseif T == Float64
      @test sprint(show, MIME"text/plain"(), pset) == """
      2 PointSet
      ├─ Point(x: 1.0 m, y: 0.0 m)
      └─ Point(x: 0.0 m, y: 1.0 m)"""
    end
  end
end
