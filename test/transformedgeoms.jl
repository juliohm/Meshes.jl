@testset "TransformedGeometry" begin
  b = Box(cart(0, 0), cart(1, 1))
  t = Translate(1, 2)
  tb = Meshes.TransformedGeometry(b, t)
  @test parent(tb) == b
  @test Meshes.transform(tb) == t
  t2 = Scale(2, 3)
  tb2 = Meshes.TransformedGeometry(tb, t2)
  @test Meshes.transform(tb2) == (t → t2)
  @test paramdim(tb) == paramdim(b)
  @test centroid(tb) == t(centroid(b))
  equaltest(tb)
  isapproxtest(tb)

  b = Ball(latlon(0, 0), T(1))
  t = Proj(Cartesian)
  tb = Meshes.TransformedGeometry(b, t)
  @test paramdim(tb) == paramdim(b)
  @test centroid(tb) == t(centroid(b))
  equaltest(tb)
  isapproxtest(tb)

  s = Sphere(latlon(0, 0), T(1))
  t = Proj(Cartesian)
  ts = Meshes.TransformedGeometry(s, t)
  @test paramdim(ts) == paramdim(s)
  @test centroid(ts) == t(centroid(s))
  equaltest(ts)
  isapproxtest(ts)

  s = Segment(cart(0, 0), cart(1, 1))
  t = Translate(1, 2)
  ts = Meshes.TransformedGeometry(s, t)
  @test vertex(ts, 1) == t(vertex(s, 1))
  @test vertices(ts) == t.(vertices(s))
  @test nvertices(ts) == nvertices(s)
  equaltest(ts)
  isapproxtest(ts)

  p = PolyArea(cart(0, 0), cart(1, 0), cart(1, 1), cart(0, 1))
  t = Translate(1, 2)
  tp = Meshes.TransformedGeometry(p, t)
  @test vertex(tp, 1) == t(vertex(p, 1))
  @test vertices(tp) == t.(vertices(p))
  @test nvertices(tp) == nvertices(p)
  @test rings(tp) == t.(rings(p))
  p2 = PolyArea(cart(0, 0), cart(0, 0), cart(1, 0), cart(1, 1), cart(0, 1))
  tp2 = Meshes.TransformedGeometry(p2, t)
  @test unique(tp2) == tp
  equaltest(tp)
  isapproxtest(tp)
end
