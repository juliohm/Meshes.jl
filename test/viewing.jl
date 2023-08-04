@testset "Viewing" begin
  @testset "Domain" begin
    g = CartesianGrid{T}(10, 10)
    v = view(g, 1:3)
    @test unview(v) == (g, 1:3)
    @test unview(g) == (g, 1:100)

    g = CartesianGrid{T}(10, 10)
    b = Box(P2(1, 1), P2(5, 5))
    v = view(g, b)
    @test v == CartesianGrid(P2(1, 1), P2(5, 5), dims=(4, 4))

    p = PointSet(collect(vertices(g)))
    v = view(p, b)
    @test centroid(v, 1) == P2(1, 1)
    @test centroid(v, nelements(v)) == P2(5, 5)

    g = CartesianGrid{T}(10, 10)
    p = PointSet(collect(vertices(g)))
    b = Ball(P2(0, 0), T(2))
    v = view(g, b)
    @test nelements(v) == 1
    @test v[1] == g[1]
    v = view(p, b)
    @test nelements(v) == 6
    @test coordinates.(v) == V2[(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (0, 2)]

    # convex polygons
    tri = Triangle(P2(5, 7), P2(10, 12), P2(15, 7))
    pent = Pentagon(P2(6, 1), P2(2, 10), P2(10, 16), P2(18, 10), P2(14, 1))

    grid = CartesianGrid{T}(20, 20)
    linds = LinearIndices(size(grid))
    @test linds[10, 10] ∈ indices(grid, tri)
    @test linds[10, 6] ∈ indices(grid, pent)

    grid = CartesianGrid(P2(-2, -2), P2(20, 20), T.((0.5, 1.5)))
    linds = LinearIndices(size(grid))
    @test linds[21, 7] ∈ indices(grid, tri)
    @test linds[21, 4] ∈ indices(grid, pent)

    grid = CartesianGrid(P2(-100, -100), P2(20, 20), T.((2, 2)))
    linds = LinearIndices(size(grid))
    @test linds[57, 54] ∈ indices(grid, tri)
    @test linds[55, 53] ∈ indices(grid, pent)

    # non-convex polygons
    poly1 = PolyArea(P2[(3, 3), (9, 9), (3, 15), (17, 15), (17, 3)])
    poly2 = PolyArea(pointify(pent), [pointify(tri)])

    grid = CartesianGrid{T}(20, 20)
    linds = LinearIndices(size(grid))
    @test linds[12, 6] ∈ indices(grid, poly1)
    @test linds[10, 3] ∈ indices(grid, poly2)

    grid = CartesianGrid(P2(-2, -2), P2(20, 20), T.((0.5, 1.5)))
    linds = LinearIndices(size(grid))
    @test linds[22, 6] ∈ indices(grid, poly1)
    @test linds[17, 4] ∈ indices(grid, poly2)

    grid = CartesianGrid(P2(-100, -100), P2(20, 20), T.((2, 2)))
    linds = LinearIndices(size(grid))
    @test linds[57, 54] ∈ indices(grid, poly1)
    @test linds[55, 53] ∈ indices(grid, poly2)

    # rotate
    poly1 = poly1 |> Rotate(Angle2d(π/2))
    poly2 = poly2 |> Rotate(Angle2d(π/2))

    grid = CartesianGrid(P2(-20, 0), P2(0, 20), T.((1, 1)))
    linds = LinearIndices(size(grid))
    @test linds[12, 12] ∈ indices(grid, poly1)
    @test linds[16, 11] ∈ indices(grid, poly2)

    grid = CartesianGrid(P2(-22, -2), P2(0, 20), T.((0.5, 1.5)))
    linds = LinearIndices(size(grid))
    @test linds[26, 8] ∈ indices(grid, poly1)
    @test linds[36, 9] ∈ indices(grid, poly2)

    grid = CartesianGrid(P2(-100, -100), P2(20, 20), T.((2, 2)))
    linds = LinearIndices(size(grid))
    @test linds[46, 57] ∈ indices(grid, poly1)
    @test linds[48, 55] ∈ indices(grid, poly2)
  end

  @testset "Data" begin
    dummydata(domain, table) = DummyData(domain, Dict(paramdim(domain) => table))
    dummymeta(domain, table) = meshdata(domain, Dict(paramdim(domain) => table))

    for dummy in [dummydata, dummymeta]
      g = CartesianGrid{T}(10, 10)
      t = (a=1:100, b=1:100)
      d = dummy(g, t)
      v = view(d, 1:3)
      @test unview(v) == (d, 1:3)
      @test unview(d) == (d, 1:100)

      g = CartesianGrid{T}(10, 10)
      t = (a=1:100, b=1:100)
      d = dummy(g, t)
      b = Box(P2(1, 1), P2(5, 5))
      v = view(d, b)
      @test domain(v) == CartesianGrid(P2(1, 1), P2(5, 5), dims=(4, 4))
      @test Tables.columntable(values(v)) == (
        a=[12, 13, 14, 15, 22, 23, 24, 25, 32, 33, 34, 35, 42, 43, 44, 45],
        b=[12, 13, 14, 15, 22, 23, 24, 25, 32, 33, 34, 35, 42, 43, 44, 45]
      )

      p = PointSet(collect(vertices(g)))
      d = dummy(p, t)
      v = view(d, b)
      dd = domain(v)
      @test centroid(dd, 1) == P2(1, 1)
      @test centroid(dd, nelements(dd)) == P2(5, 5)
      tt = Tables.columntable(values(v))
      @test tt == (
        a=[13, 14, 15, 16, 17, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 57, 58, 59, 60, 61],
        b=[13, 14, 15, 16, 17, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 57, 58, 59, 60, 61]
      )

      g = CartesianGrid{T}(250, 250)
      t = (a=rand(250 * 250), b=rand(250 * 250))
      d = dummy(g, t)
      s1 = slice(d, T(50.5):T(100.2), T(41.7):T(81.3))
      d1 = domain(s1)
      pts1 = [centroid(d1, i) for i in 1:nelements(d1)]
      X1 = reduce(hcat, coordinates.(pts1))
      @test all(T[50.5, 41.7] .≤ minimum(X1, dims=2))
      @test all(maximum(X1, dims=2) .≤ T[100.2, 81.3])

      p = sample(d, 100)
      s2 = slice(p, T(50.5):T(150.7), T(175.2):T(250.3))
      d2 = domain(s2)
      pts2 = [centroid(d2, i) for i in 1:nelements(d2)]
      X2 = reduce(hcat, coordinates.(pts2))
      @test all(T[50.5, 175.2] .≤ minimum(X2, dims=2))
      @test all(maximum(X2, dims=2) .≤ T[150.7, 250.3])
    end
  end
end
