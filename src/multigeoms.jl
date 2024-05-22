# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Multi(geoms)

A collection of geometries `geoms` seen as a single [`Geometry`](@ref).

In geographic information systems (GIS) it is common to represent
multiple polygons as a single entity (e.g. country with islands).

### Notes

- Type aliases are [`MultiPoint`](@ref), [`MultiSegment`](@ref),
  [`MultiRope`](@ref), [`MultiRing`](@ref), [`MultiPolygon`](@ref).
"""
struct Multi{Dim,G<:Geometry{Dim}} <: Geometry{Dim}
  geoms::Vector{G}
end

# constructor with iterator of geometries
Multi(geoms) = Multi(collect(geoms))

# type aliases for convenience
const MultiPoint{Dim} = Multi{Dim,<:Point{Dim}}
const MultiSegment{Dim} = Multi{Dim,<:Segment{Dim}}
const MultiRope{Dim} = Multi{Dim,<:Rope{Dim}}
const MultiRing{Dim} = Multi{Dim,<:Ring{Dim}}
const MultiPolygon{Dim} = Multi{Dim,<:Polygon{Dim}}
const MultiPolyhedron{Dim} = Multi{Dim,<:Polyhedron{Dim}}

paramdim(m::Multi) = maximum(paramdim, m.geoms)

lentype(::Type{<:Multi{Dim,G}}) where {Dim,G} = lentype(G)

vertex(m::Multi, ind) = vertices(m)[ind]

vertices(m::Multi) = [vertex for geom in m.geoms for vertex in vertices(geom)]

nvertices(m::Multi) = sum(nvertices, m.geoms)

Base.unique(m::Multi) = unique!(deepcopy(m))

function Base.unique!(m::Multi)
  foreach(unique!, m.geoms)
  m
end

function centroid(m::Multi)
  cs = to.(centroid.(m.geoms))
  Point(coords(sum(cs) / length(cs)))
end

rings(m::MultiPolygon) = [ring for poly in m.geoms for ring in rings(poly)]

Base.parent(m::Multi) = m.geoms

==(m₁::Multi, m₂::Multi) = length(m₁.geoms) == length(m₂.geoms) && all(g -> g[1] == g[2], zip(m₁.geoms, m₂.geoms))

Base.isapprox(m₁::Multi, m₂::Multi) = all(g -> g[1] ≈ g[2], zip(m₁.geoms, m₂.geoms))

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, m::Multi)
  name = prettyname(eltype(m.geoms))
  print(io, "Multi$name")
end

function Base.show(io::IO, m::Multi)
  print(io, "Multi(")
  geoms = prettyname.(m.geoms)
  counts = ("$(count(==(g), geoms))×$g" for g in unique(geoms))
  join(io, counts, ", ")
  print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", m::Multi)
  summary(io, m)
  println(io)
  printelms(io, m.geoms)
end
