# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Cone(base, apex)

A cone with `base` disk and `apex`.
See <https://en.wikipedia.org/wiki/Cone>.

See also [`ConeSurface`](@ref).
"""
struct Cone{M<:AbstractManifold,C<:CRS,D<:Disk{M,C}} <: Primitive{M,C}
  base::D
  apex::Point{M,C}
end

function Cone(base::Disk{M,C}, apex::Tuple) where {M<:AbstractManifold,C<:Cartesian}
  coords = convert(C, Cartesian{datum(C)}(apex))
  Cone(base, Point{M}(coords))
end

paramdim(::Type{<:Cone}) = 3

base(c::Cone) = c.base

apex(c::Cone) = c.apex

height(c::Cone) = norm(center(base(c)) - apex(c))

halfangle(c::Cone) = atan(radius(base(c)), height(c))

==(c₁::Cone, c₂::Cone) = boundary(c₁) == boundary(c₂)

Base.isapprox(c₁::Cone, c₂::Cone; atol=atol(lentype(c₁)), kwargs...) =
  isapprox(boundary(c₁), boundary(c₂); atol, kwargs...)
