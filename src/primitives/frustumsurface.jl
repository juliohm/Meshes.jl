# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    FrustumSurface(bot, top)

A frustum (truncated cone) surface with `bot` and `top` disks.
See <https://en.wikipedia.org/wiki/Frustum>.

See also [`Frustum`](@ref).
"""
struct FrustumSurface{D<:Disk} <: Primitive{3}
  bot::D
  top::D

  function FrustumSurface{D}(bot, top) where {D}
    bn = normal(plane(bot))
    tn = normal(plane(top))
    @assert bn ⋅ tn ≈ 1 "Bottom and top plane must be parallel"
    @assert center(bot) ≉ center(top) "Bottom and top centers need to be distinct"
    new(bot, top)
  end
end

FrustumSurface(bot::D, top::D) where {D<:Disk} = FrustumSurface{D}(bot, top)

paramdim(::Type{<:FrustumSurface}) = 2

lentype(::Type{<:FrustumSurface{D}}) where {D} = lentype(D)

bottom(f::FrustumSurface) = f.bot

top(f::FrustumSurface) = f.top

height(f::FrustumSurface) = norm(center(bottom(f)) - center(top(f)))

axis(f::FrustumSurface) = Line(center(bottom(f)), center(top(f)))

function (f::FrustumSurface)(φ, z)
  ℒ = lentype(c)
  T = numtype(ℒ)
  if (φ < 0 || φ > 1) || (z < 0 || z > 1)
    throw(DomainError((φ, z), "f(φ, z) is not defined for φ, z outside [0, 1]²."))
  end
  rb = radius(bottom(f))
  rt = radius(top(f))
  a = axis(f)
  d = a(1) - a(0)
  l = norm(d)

  # rotation to align z axis with cylinder axis
  Q = rotation_between(d, Vec(zero(ℒ), zero(ℒ), oneunit(ℒ)))

  # scale coordinates
  φₛ = 2T(π) * φ
  zₛ = z * l

  # local coordinates, that will be transformed with rotation and position of the FrustumSurface
  x = cos(φₛ) * (rb * (l - zₛ) + rt * zₛ) / l
  y = sin(φₛ) * (rb * (l - zₛ) + rt * zₛ) / l
  z = zₛ
  p = Vec(x, y, z)

  center(bottom(f)) + Q' * p
end

# TODO
# function Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{FrustumSurface{T}}) where {T}
#   bottom = rand(rng, Disk{T})
#   ax = normal(plane(bottom))
#   topplane = Plane{T}(center(bottom) + rand(T) * ax, ax)
#   top = Disk{T}(topplane, rand(T))
#   FrustumSurface(bottom, top)
# end
