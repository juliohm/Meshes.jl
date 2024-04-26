# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Ball(center, radius)

A ball with `center` and `radius`.

See also [`Sphere`](@ref).
"""
struct Ball{Dim,P<:Point{Dim},ℒ<:Len} <: Primitive{Dim}
  center::P
  radius::ℒ
  Ball(center::P, radius::ℒ) where {Dim,P<:Point{Dim},ℒ<:Len} = new{Dim,P,float(ℒ)}(center, radius)
end

Ball(center::Point, radius) = Ball(center, addunit(radius, u"m"))

Ball(center::Tuple, radius) = Ball(Point(center), radius)

Ball(center::Point) = Ball(center, 1.0u"m")

Ball(center::Tuple) = Ball(Point(center))

paramdim(::Type{<:Ball{Dim}}) where {Dim} = Dim

lentype(::Type{<:Ball{Dim,P}}) where {Dim,P} = lentype(P)

center(b::Ball) = b.center

radius(b::Ball) = b.radius

function (b::Ball{2})(ρ, φ)
  T = numtype(lentype(b))
  if (ρ < 0 || ρ > 1) || (φ < 0 || φ > 1)
    throw(DomainError((ρ, φ), "b(ρ, φ) is not defined for ρ, φ outside [0, 1]²."))
  end
  c = b.center
  r = b.radius
  l = T(ρ) * r
  sφ, cφ = sincospi(2 * T(φ))
  x = l * cφ
  y = l * sφ
  c + Vec(x, y)
end

function (b::Ball{3})(ρ, θ, φ)
  T = numtype(lentype(b))
  if (ρ < 0 || ρ > 1) || (θ < 0 || θ > 1) || (φ < 0 || φ > 1)
    throw(DomainError((ρ, θ, φ), "b(ρ, θ, φ) is not defined for ρ, θ, φ outside [0, 1]³."))
  end
  c = b.center
  r = b.radius
  l = T(ρ) * r
  sθ, cθ = sincospi(T(θ))
  sφ, cφ = sincospi(2 * T(φ))
  x = l * sθ * cφ
  y = l * sθ * sφ
  z = l * cθ
  c + Vec(x, y, z)
end

Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Ball{Dim}}) where {Dim} =
  Ball(rand(rng, Point{Dim}), rand(rng, Met{Float64}))
