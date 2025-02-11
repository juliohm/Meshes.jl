# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    IntersectionType

The different types of intersection that may occur between geometries.
Type `IntersectionType` in a Julia session to see the full list.
"""
@enum IntersectionType begin
  # crossing types
  Crossing
  CornerCrossing
  EdgeCrossing

  # touching types
  Touching
  CornerTouching
  EdgeTouching

  # overlapping types
  Overlapping
  PosOverlapping
  NegOverlapping

  # no much information
  NotIntersecting
  Intersecting
end

"""
    Intersection{G}

An intersection between geometries holding a geometry of type `G`.
"""
struct Intersection{GeometryType}
  type::IntersectionType
  geom::GeometryType
end

Intersection(type, geom) = Intersection{typeof(geom)}(type, geom)

"""
    type(intersection)

Return the type of intersection computed between geometries.
"""
type(I::Intersection) = I.type

"""
    get(intersection)

Return the underlying geometry stored in the intersection object.
"""
Base.get(I::Intersection) = I.geom

# helper macro for developers in case we decide to
# change the internal representation of Intersection
macro IT(type, geom, func)
  type = esc(type)
  geom = esc(geom)
  func = esc(func)
  :(Intersection($type, $geom) |> $func)
end

"""
    g₁ ∩ g₂

Return the intersection of two geometries or domains `g₁` and `g₂`
as a new (multi-)geometry.
"""
Base.intersect(g₁::GeometryOrDomain, g₂::GeometryOrDomain) = get(intersection(g₁, g₂))

"""
    intersection([f], g₁, g₂)

Compute the intersection of two geometries or domains `g₁` and `g₂`
and apply function `f` to it. Default function is `identity`.

## Examples

```julia
intersection(g₁, g₂) do I
  if I isa CrossingLines
    # do something
  else
    # do nothing
  end
end
```

### Notes

When a custom function `f` is used that reduces the number of
return types, Julia is able to optimize the branches of the code
and generate specialized code. This is not the case when
`f === identity`.
"""
intersection(f, g₁, g₂) = intersection(f, g₂, g₁)
intersection(g₁, g₂) = intersection(identity, g₁, g₂)

# ----------------
# IMPLEMENTATIONS
# ----------------

# order of geometries according to following convention:
# https://github.com/JuliaGeometry/Meshes.jl/issues/325
include("intersections/points.jl")
include("intersections/segments.jl")
include("intersections/rays.jl")
include("intersections/lines.jl")
include("intersections/chains.jl")
include("intersections/planes.jl")
include("intersections/boxes.jl")
include("intersections/polygons.jl")
include("intersections/domains.jl")
include("intersections/sweepline.jl")
