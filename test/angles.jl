@testset "Angles" begin
  # 2D points
  @test ∠(P2(0,1),P2(0,0),P2(1,0)) ≈ T(-π/2)
  @test ∠(P2(1,0),P2(0,0),P2(0,1)) ≈ T(π/2)
  @test ∠(P2(-1,0),P2(0,0),P2(0,1)) ≈ T(-π/2)
  @test ∠(P2(0,1),P2(0,0),P2(-1,0)) ≈ T(π/2)
  @test ∠(P2(0,-1),P2(0,0),P2(1,0)) ≈ T(π/2)
  @test ∠(P2(1,0),P2(0,0),P2(0,-1)) ≈ T(-π/2)
  @test ∠(P2(0,-1),P2(0,0),P2(-1,0)) ≈ T(-π/2)
  @test ∠(P2(-1,0),P2(0,0),P2(0,-1)) ≈ T(π/2)

  # 3D points
  @test ∠(P3(1,0,0),P3(0,0,0),P3(0,1,0)) ≈ T(π/2)
  @test ∠(P3(1,0,0),P3(0,0,0),P3(0,0,1)) ≈ T(π/2)
  @test ∠(P3(0,1,0),P3(0,0,0),P3(1,0,0)) ≈ T(π/2)
  @test ∠(P3(0,1,0),P3(0,0,0),P3(0,0,1)) ≈ T(π/2)
  @test ∠(P3(0,0,1),P3(0,0,0),P3(1,0,0)) ≈ T(π/2)
  @test ∠(P3(0,0,1),P3(0,0,0),P3(0,1,0)) ≈ T(π/2)
  
  # Ngon
  t = Triangle(P2(0,0), P2(1,0), P2(0,1))
  @test all(isapprox.(rad2deg.(angles(t)), T[-90, -45, -45], atol=atol(T)))
  @test all(isapprox.(rad2deg.(innerangles(t)), T[90, 45, 45], atol=atol(T)))     
end
