@testitem "SutherlandHodgman" setup = [Setup] begin
  # triangle
  poly = Triangle(cart(6, 2), cart(3, 5), cart(0, 2))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  @test issimple(clipped)
  @test all(vertices(clipped) .≈ [cart(5, 3), cart(4, 4), cart(2, 4), cart(0, 2), cart(5, 2)])

  # octagon
  poly = Octagon(cart(8, -2), cart(8, 5), cart(2, 5), cart(4, 3), cart(6, 3), cart(4, 1), cart(2, 1), cart(2, -2))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  @test !issimple(clipped)
  @test all(
    vertices(clipped) .≈
    [cart(3, 4), cart(4, 3), cart(5, 3), cart(5, 2), cart(4, 1), cart(2, 1), cart(2, 0), cart(5, 0), cart(5, 4)]
  )

  # inside
  poly = Quadrangle(cart(1, 0), cart(1, 1), cart(0, 1), cart(0, 0))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  @test issimple(clipped)
  @test all(vertices(clipped) .≈ vertices(poly))

  # outside
  poly = Quadrangle(cart(7, 6), cart(7, 7), cart(6, 7), cart(6, 6))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  @test isnothing(clipped)

  # surrounded
  poly = Hexagon(cart(0, 2), cart(-2, 2), cart(-2, 0), cart(0, -2), cart(2, -2), cart(2, 0))
  other = Hexagon(cart(1, 0), cart(0, 1), cart(-1, 1), cart(-1, 0), cart(0, -1), cart(1, -1))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  @test issimple(clipped)
  @test all(vertices(clipped) .≈ vertices(other))

  # PolyArea with box
  outer = Ring(cart(8, 0), cart(4, 8), cart(2, 8), cart(-2, 0), cart(0, 0), cart(1, 2), cart(5, 2), cart(6, 0))
  inner = Ring(cart(4, 4), cart(2, 4), cart(3, 6))
  poly = PolyArea([outer, inner])
  other = Box(cart(0, 1), cart(3, 7))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  crings = rings(clipped)
  @test !issimple(clipped)
  @test all(
    vertices(crings[1]) .≈
    [cart(1.5, 7.0), cart(0.0, 4.0), cart(0.0, 1.0), cart(0.5, 1.0), cart(1.0, 2.0), cart(3.0, 2.0), cart(3.0, 7.0)]
  )
  @test all(vertices(crings[2]) .≈ [cart(3.0, 4.0), cart(2.0, 4.0), cart(3.0, 6.0)])

  # PolyArea with outer ring outside and inner ring inside
  outer = Ring(cart(8, 0), cart(2, 6), cart(-4, 0))
  inner = Ring(cart(1, 3), cart(3, 3), cart(3, 1), cart(1, 1))
  poly = PolyArea([outer, inner])
  other = Quadrangle(cart(4, 4), cart(0, 4), cart(0, 0), cart(4, 0))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  @test !issimple(clipped)
  crings = rings(clipped)
  @test all(vertices(crings[1]) .≈ vertices(other))
  @test all(vertices(crings[2]) .≈ vertices(inner))

  # PolyArea with one inner ring inside `other` and another inner ring outside `other`
  outer = Ring(cart(6, 4), cart(6, 7), cart(1, 6), cart(1, 1), cart(5, 2))
  inner₁ = Ring(cart(3, 3), cart(3, 4), cart(4, 3))
  inner₂ = Ring(cart(2, 5), cart(2, 6), cart(3, 5))
  poly = PolyArea([outer, inner₁, inner₂])
  other = PolyArea(Ring(cart(6, 1), cart(7, 2), cart(6, 5), cart(0, 2), cart(1, 1)))
  clipped = clip(poly, other, SutherlandHodgmanClipping())
  crings = rings(clipped)
  @test !issimple(clipped)
  @test length(crings) == 2
  @test all(vertices(crings[1]) .≈ [cart(6, 4), cart(6, 5), cart(1, 2.5), cart(1, 1), cart(5, 2)])
  @test all(vertices(crings[2]) .≈ [cart(3.0, 3.0), cart(3.0, 3.5), cart(10 / 3, 11 / 3), cart(4.0, 3.0)])
end

@testitem "WeilerAtherton" setup = [Setup] begin
  # triangle
  poly = Triangle(cart(6, 2), cart(3, 5), cart(0, 2))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, WeilerAthertonClipping())
  @test issimple(clipped)
  @test all(vertices(clipped) .≈ [cart(2, 4), cart(0, 2), cart(5, 2), cart(5, 3), cart(4, 4)])

  # octagon
  poly = Octagon(cart(8, -2), cart(8, 5), cart(2, 5), cart(4, 3), cart(6, 3), cart(4, 1), cart(2, 1), cart(2, -2))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, WeilerAthertonClipping())
  @test all(
    vertices(clipped) .≈
    [cart(3, 4), cart(4, 3), cart(5, 3), cart(5, 4), cart(5, 2), cart(4, 1), cart(2, 1), cart(2, 0), cart(5, 0)]
  )

  # inside
  poly = Quadrangle(cart(1, 0), cart(1, 1), cart(0, 1), cart(0, 0))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, WeilerAthertonClipping())
  @test issimple(clipped)
  @test clipped ≗ poly

  # outside
  poly = Quadrangle(cart(7, 6), cart(7, 7), cart(6, 7), cart(6, 6))
  other = Quadrangle(cart(5, 0), cart(5, 4), cart(0, 4), cart(0, 0))
  clipped = clip(poly, other, WeilerAthertonClipping())
  @test isnothing(clipped)

  # surrounded
  poly = Hexagon(cart(0, 2), cart(-2, 2), cart(-2, 0), cart(0, -2), cart(2, -2), cart(2, 0))
  other = Hexagon(cart(1, 0), cart(0, 1), cart(-1, 1), cart(-1, 0), cart(0, -1), cart(1, -1))
  clipped = clip(poly, other, WeilerAthertonClipping())
  @test issimple(clipped)
  @test clipped ≗ other

  # PolyArea with box
  outer = Ring(cart(8, 0), cart(4, 8), cart(2, 8), cart(-2, 0), cart(0, 0), cart(1, 2), cart(5, 2), cart(6, 0))
  inner = Ring(cart(4, 4), cart(2, 4), cart(3, 6))
  poly = PolyArea([outer, inner])
  other = Box(cart(0, 1), cart(3, 7))
  clipped = clip(poly, other, WeilerAthertonClipping())
  crings = rings(clipped)
  @test issimple(clipped)
  @test all(
    vertices(crings[1]) .≈ [
      cart(3.0, 4.0),
      cart(2.0, 4.0),
      cart(3.0, 6.0),
      cart(3.0, 7.0),
      cart(1.5, 7.0),
      cart(0.0, 4.0),
      cart(0.0, 1.0),
      cart(0.5, 1.0),
      cart(1.0, 2.0),
      cart(3.0, 2.0)
    ]
  )

  # PolyArea with outer ring outside and inner ring inside
  outer = Ring(cart(8, 0), cart(2, 6), cart(-4, 0))
  inner = Ring(cart(1, 3), cart(3, 3), cart(3, 1), cart(1, 1))
  poly = PolyArea([outer, inner])
  other = Quadrangle(cart(4, 4), cart(0, 4), cart(0, 0), cart(4, 0))
  clipped = clip(poly, other, WeilerAthertonClipping())
  @test !issimple(clipped)
  crings = rings(clipped)
  @test crings[1] ≗ Ring([cart(4, 0), cart(4, 4), cart(0, 4), cart(0, 0)])
  @test crings[2] ≗ inner

  # PolyArea with one inner ring inside `other` and another inner ring outside `other`
  outer = Ring(cart(6, 4), cart(6, 7), cart(1, 6), cart(1, 1), cart(5, 2))
  inner₁ = Ring(cart(3, 3), cart(3, 4), cart(4, 3))
  inner₂ = Ring(cart(2, 5), cart(2, 6), cart(3, 5))
  poly = PolyArea([outer, inner₁, inner₂])
  other = PolyArea(Ring(cart(6, 1), cart(7, 2), cart(6, 5), cart(0, 2), cart(1, 1)))
  clipped = clip(poly, other, WeilerAthertonClipping())
  crings = rings(clipped)
  @test issimple(clipped)
  @test length(crings) == 1
  @test all(
    vertices(crings[1]) .≈ [
      cart(1, 2.5),
      cart(1, 1),
      cart(5, 2),
      cart(6, 4),
      cart(6, 5),
      cart(10 / 3, 11 / 3),
      cart(4.0, 3.0),
      cart(3.0, 3.0),
      cart(3.0, 3.5)
    ]
  )

  # Overlapping clipping polygon with the edges of the hole of the subject polygon.
  triangle = Triangle((0.0, 0.0), (1.0, 0.0), (0.5, 1.0))
  rectangle = Quadrangle((0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0))
  poly = PolyArea(rings(rectangle)[1], reverse(rings(triangle |> Scale(0.5) |> Translate((0.3, 0.3)))[1]))
  other = triangle |> Scale(0.9) |> Translate(0.1, -0.1)
  clipped = clip(poly, other, WeilerAthertonClipping())
  crings = rings(clipped)
  @test length(crings) == 1
  @test all(
    isapprox.(
      vertices(crings[1]),
      [cart(0.8, 0.3), cart(0.3, 0.3), cart(0.15, 0.0), cart(0.95, 0.0)],
    )
  )
end
