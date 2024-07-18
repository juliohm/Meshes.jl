# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Geometry{CRS}

A geometry with given coordinate reference system `CRS`.
"""
abstract type Geometry{CRS} end

Broadcast.broadcastable(g::Geometry) = Ref(g)

"""
    embeddim(geometry)

Return the number of dimensions of the space where the `geometry` is embedded.
"""
embeddim(::Type{<:Geometry{CRS}}) where {CRS} = CoordRefSystems.ndims(CRS)
embeddim(g::Geometry) = embeddim(typeof(g))

"""
    paramdim(geometry)

Return the number of parametric dimensions of the `geometry`. For example, a
sphere embedded in 3D has 2 parametric dimensions (polar and azimuthal angles).

See also [`isparametrized`](@ref).
"""
paramdim(g::Geometry) = paramdim(typeof(g))

"""
    crs(geometry)

Return the coordinate reference system (CRS) of the `geometry`.
"""
crs(::Type{<:Geometry{CRS}}) where {CRS} = CRS
crs(g::Geometry) = crs(typeof(g))

"""
    lentype(geometry)

Return the length type of the `geometry`.
"""
lentype(::Type{<:Geometry{CRS}}) where {CRS} = lentype(CRS)
lentype(g::Geometry) = lentype(typeof(g))

"""
    centroid(geometry)

Return the centroid of the `geometry`.
"""
centroid(g::Geometry) = center(g)

"""
    extrema(geometry)

Return the top left and bottom right corners of the
bounding box of the `geometry`.
"""
Base.extrema(g::Geometry) = extrema(boundingbox(g))

# -----------
# IO METHODS
# -----------

Base.summary(io::IO, geom::Geometry) = print(io, prettyname(geom))

# ----------------
# IMPLEMENTATIONS
# ----------------

include("primitives.jl")
include("polytopes.jl")
include("multigeoms.jl")

# ------------
# CONVERSIONS
# ------------

# TODO: check dim: 2
Base.convert(::Type{<:Quadrangle}, b::Box) = Quadrangle(vertices(boundary(b))...)

# TODO: check dim: 3
Base.convert(::Type{<:Hexahedron}, b::Box) = Hexahedron(vertices(boundary(b))...)
