# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Cone(base, apex)

A cone with `base` disk and `apex`.
See <https://en.wikipedia.org/wiki/Cone>.

See also [`ConeSurface`](@ref).
"""
struct Cone{D<:Disk,P<:Point{3}} <: Primitive{3}
  base::D
  apex::P
end

Cone(base::Disk, apex::Tuple) = Cone(base, Point(apex))

paramdim(::Type{<:Cone}) = 3

coordtype(::Type{<:Cone{D}}) where {D} = coordtype(D)

base(c::Cone) = c.base

apex(c::Cone) = c.apex

height(c::Cone) = norm(center(base(c)) - apex(c))

halfangle(c::Cone) = atan(radius(base(c)), height(c))

# TODO
# Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Cone{T}}) where {T} =
#   Cone(rand(rng, Disk{T}), rand(rng, Point{3,T}))
