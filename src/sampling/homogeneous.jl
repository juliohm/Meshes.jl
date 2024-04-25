# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    HomogeneousSampling(size, [weights])

Generate sample of given `size` from geometric object
according to a homogeneous density. Optionally, provide `weights`
to specify custom sampling weights for the elements of a domain.
"""
struct HomogeneousSampling{W} <: ContinuousSamplingMethod
  size::Int
  weights::W
end

HomogeneousSampling(size::Int) = HomogeneousSampling(size, nothing)

function sample(rng::AbstractRNG, d::Domain, method::HomogeneousSampling)
  size = method.size
  weights = isnothing(method.weights) ? measure.(d) : method.weights

  # sample elements with weights
  w = WeightedSampling(size, weights, replace=true)

  # within each element sample a single point
  h = HomogeneousSampling(1)

  (first(sample(rng, e, h)) for e in sample(rng, d, w))
end

function sample(rng::AbstractRNG, geom::Geometry, method::HomogeneousSampling)
  if isparametrized(geom)
    randpoint() = geom(rand(rng, coordtype(geom), paramdim(geom))...)
    (randpoint() for _ in 1:(method.size))
  else
    sample(rng, discretize(geom), method)
  end
end

# --------------
# SPECIAL CASES
# --------------

function sample(rng::AbstractRNG, triangle::Triangle, method::HomogeneousSampling)
  function randpoint()
    # sample barycentric coordinates
    u₁, u₂ = rand(rng, coordtype(triangle), 2)
    λ₁, λ₂ = 1 - √u₁, u₂ * √u₁
    triangle(λ₁, λ₂)
  end
  (randpoint() for _ in 1:(method.size))
end

function sample(rng::AbstractRNG, tetrahedron::Tetrahedron, method::HomogeneousSampling)
  @error "not implemented"
end

function sample(rng::AbstractRNG, ball::Ball{2}, method::HomogeneousSampling)
  function randpoint()
    u₁, u₂ = rand(rng, coordtype(ball), 2)
    ball(√u₁, u₂)
  end
  (randpoint() for _ in 1:(method.size))
end

function sample(rng::AbstractRNG, ball::Ball{3}, method::HomogeneousSampling)
  function randpoint()
    u₁, u₂, u₃ = rand(rng, coordtype(ball), 3)
    ball(∛u₁, acos(1 - 2u₂) / T(π), u₃)
  end
  (randpoint() for _ in 1:(method.size))
end
