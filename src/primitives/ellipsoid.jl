# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Ellipsoid(radii, center=(0, 0, 0), rotation=I)

A 3D ellipsoid with given `radii`, `center` and `rotation`.
"""
struct Ellipsoid{L<:Len,P<:Point{3},R} <: Primitive{3}
  radii::NTuple{3,L}
  center::P
  rotation::R
  Ellipsoid(radii::NTuple{3,L}, center::P, rotation::R) where {L<:Len,P<:Point{3},R} =
    new{float(L),P,R}(radii, center, rotation)
end

Ellipsoid(radii::NTuple{3}, center::P, rotation::R) where {P<:Point{3},R} =
  Ellipsoid(addunit.(radii, u"m"), center, rotation)

Ellipsoid(radii::NTuple{3}, center=(0, 0, 0), rotation=I) = Ellipsoid(radii, Point(center), rotation)

paramdim(::Type{<:Ellipsoid}) = 2

coordtype(::Type{<:Ellipsoid{L,P}}) where {L,P} = coordtype(P)

radii(e::Ellipsoid) = e.radii

center(e::Ellipsoid) = e.center

rotation(e::Ellipsoid) = e.rotation

function (e::Ellipsoid{L})(θ, φ) where {L}
  if (θ < 0 || θ > 1) || (φ < 0 || φ > 1)
    throw(DomainError((θ, φ), "e(θ, φ) is not defined for θ, φ outside [0, 1]²."))
  end
  r = e.radii
  c = e.center
  R = e.rotation
  sθ, cθ = sincospi(L(θ))
  sφ, cφ = sincospi(2 * L(φ))
  x = r[1] * sθ * cφ
  y = r[2] * sθ * sφ
  z = r[3] * cθ
  c + R * Vec(x, y, z)
end

# TODO
# Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Ellipsoid{T}}) where {T} =
#   Ellipsoid((rand(rng, T), rand(rng, T), rand(rng, T)), rand(rng, Point{3,T}), rand(rng, QuatRotation))
