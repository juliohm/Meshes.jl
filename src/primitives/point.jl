# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

asvec(coords::Cartesian) = Vec(CoordRefSystems._coords(coords))
ascart(vec::Vec) = Cartesian(Tuple(vec))

"""
    Point(x₁, x₂, ..., xₙ)
    Point((x₁, x₂, ..., xₙ))

A point in `Dim`-dimensional space with coordinates in length units (default to meters).

The coordinates of the point are given with respect to the canonical
Euclidean basis, and integer coordinates are converted to float.

## Examples

```julia
# 2D points
Point(1.0, 2.0) # add default units
Point(1.0u"m", 2.0u"m") # double precision as expected
Point(1f0u"km", 2f0u"km") # single precision as expected
Point(1u"m", 2u"m") # integer is converted to float by design

# 3D points
Point(1.0, 2.0, 3.0) # add default units
Point(1.0u"m", 2.0u"m", 3.0u"m") # double precision as expected
Point(1f0u"km", 2f0u"km", 3f0u"km") # single precision as expected
Point(1u"m", 2u"m", 3u"m") # integer is converted to float by design
```

### Notes

- Integer coordinates are not supported because most geometric processing
  algorithms assume a continuous space. The conversion to float avoids
  `InexactError` and other unexpected results.
"""
struct Point{Dim,C<:CRS} <: Primitive{Dim}
  coords::C
  Point(coords::C) where {C<:CRS} = new{CoordRefSystems.ndims(coords),C}(coords)
end

# convenience constructors
Point(coords...) = Point(Cartesian(coords...))
Point(coords::Tuple) = Point(Cartesian(coords...))

paramdim(::Type{<:Point}) = 0

center(p::Point) = p

==(A::Point, B::Point) = A.coords == B.coords

Base.isapprox(A::Point, B::Point; atol=CoordRefSystems.tol(A.coords), kwargs...) =
  isapprox(A.coords, B.coords; atol, kwargs...)

# TODO: should the coordinate function return a Vec?
# MOTIVATION: most uses of this function expect the return to be vector
"""
    coordinates(point)

Return the coordinates of the `point` with respect to the
canonical Euclidean basis.
"""
coordinates(A::Point) = A.coords

"""
    -(A::Point, B::Point)

Return the [`Vec`](@ref) associated with the direction
from point `B` to point `A`.
"""
-(A::Point{Dim,<:Cartesian}, B::Point{Dim,<:Cartesian}) where {Dim} = asvec(A.coords) - asvec(B.coords)

"""
    +(A::Point, v::Vec)
    +(v::Vec, A::Point)

Return the point at the end of the vector `v` placed
at a reference (or start) point `A`.
"""
+(A::Point{Dim,<:Cartesian}, v::Vec{Dim}) where {Dim} = Point(ascart(asvec(A.coords) + v))
+(v::Vec{Dim}, A::Point{Dim,<:Cartesian}) where {Dim} = A + v

"""
    -(A::Point, v::Vec)
    -(v::Vec, A::Point)

Return the point at the end of the vector `-v` placed
at a reference (or start) point `A`.
"""
-(A::Point{Dim,<:Cartesian}, v::Vec{Dim}) where {Dim} = Point(ascart(asvec(A.coords) - v))
-(v::Vec{Dim}, A::Point{Dim,<:Cartesian}) where {Dim} = A - v

"""
    ⪯(A::Point, B::Point)
    ⪰(A::Point, B::Point)
    ≺(A::Point, B::Point)
    ≻(A::Point, B::Point)

Generalized inequality for non-negative orthant Rⁿ₊.
"""
⪯(A::Point{Dim,<:Cartesian}, B::Point{Dim,<:Cartesian}) where {Dim} = all(≥(0u"m"), B - A)
⪰(A::Point{Dim,<:Cartesian}, B::Point{Dim,<:Cartesian}) where {Dim} = all(≥(0u"m"), A - B)
≺(A::Point{Dim,<:Cartesian}, B::Point{Dim,<:Cartesian}) where {Dim} = all(>(0u"m"), B - A)
≻(A::Point{Dim,<:Cartesian}, B::Point{Dim,<:Cartesian}) where {Dim} = all(>(0u"m"), A - B)

"""
    ∠(A, B, C)

Angle ∠ABC between rays BA and BC.
See <https://en.wikipedia.org/wiki/Angle>.

Uses the two-argument form of `atan` returning value in range [-π, π]
in 2D and [0, π] in 3D.
See <https://en.wikipedia.org/wiki/Atan2>.

## Examples

```julia
∠(Point(1,0), Point(0,0), Point(0,1)) == π/2
```
"""
∠(A::P, B::P, C::P) where {P<:Point{2}} = ∠(A - B, C - B)
∠(A::P, B::P, C::P) where {P<:Point{3}} = ∠(A - B, C - B)

# TODO
# Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Point{Dim,T}}) where {Dim,T} = Point(rand(rng, Vec{Dim,T}))

# -----------
# IO METHODS
# -----------

function Base.show(io::IO, point::Point)
  if get(io, :compact, false)
    print(io, "(")
    _printfields(io, point.coords)
    print(io, ")")
  else
    print(io, "Point(")
    _printfields(io, point.coords)
    print(io, ")")
  end
end

_printfields(io, coords::CRS) = printfields(io, coords, compact=true)
_printfields(io, coords::CoordRefSystems.ShiftedCRS) = printfields(io, CoordRefSystems._coords(coords), compact=true)
_printfields(io, coords::Cartesian) =
  printfields(io, CoordRefSystems._coords(coords), CoordRefSystems._fnames(coords), compact=true)

function Base.show(io::IO, mime::MIME"text/plain", point::Point)
  print(io, "Point with ")
  show(io, mime, point.coords)
end
