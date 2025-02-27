# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GeometricTransform

A method to transform the geometry (e.g. coordinates) of objects.
See [https://en.wikipedia.org/wiki/Geometric_transformation]
(https://en.wikipedia.org/wiki/Geometric_transformation).
"""
abstract type GeometricTransform <: Transform end

"""
    isaffine(transform)

Tells whether or not the geometric `transform` is Affine,
i.e. it can be defined as a muladd operation (`Ax + b`).
"""
isaffine(t::GeometricTransform) = isaffine(typeof(t))
isaffine(::Type{<:GeometricTransform}) = false

# fallback with raw vector of geometries for convenience
function apply(t::GeometricTransform, g::AbstractVector{<:Geometry})
  n, c = apply(t, GeometrySet(g))
  parent(n), c
end

# fallback with raw vector of geometries for convenience
function revert(t::GeometricTransform, g::AbstractVector{<:Geometry}, c)
  o = revert(t, GeometrySet(g), c)
  parent(o)
end

"""
    CoordinateTransform

A method to transform the coordinates of objects.
See <https://en.wikipedia.org/wiki/List_of_common_coordinate_transformations>.
"""
abstract type CoordinateTransform <: GeometricTransform end

"""
    applycoord(transform, object)

Recursively apply coordinate `transform` on `object`.
This function is intended for developers of new
[`CoordinateTransform`](@ref).
"""
function applycoord end

# --------------------
# TRANSFORM FALLBACKS
# --------------------

apply(t::CoordinateTransform, v::Vec) = applycoord(t, v), nothing

revert(t::CoordinateTransform, v::Vec, c) = applycoord(inverse(t), v)

apply(t::CoordinateTransform, g::GeometryOrDomain) = applycoord(t, g), nothing

revert(t::CoordinateTransform, g::GeometryOrDomain, c) = applycoord(inverse(t), g)

# apply transform recursively
@generated function applycoord(t::CoordinateTransform, g::G) where {G<:GeometryOrDomain}
  ctor = constructor(G)
  names = fieldnames(G)
  exprs = (:(applycoord(t, g.$name)) for name in names)
  :($ctor($(exprs...)))
end

# stop recursion at non-geometric types
applycoord(::CoordinateTransform, x) = x

# special treatment for TransformedGeometry
applycoord(t::CoordinateTransform, g::TransformedGeometry) = TransformedGeometry(g, t)

# special treatment for TransformedMesh
applycoord(t::CoordinateTransform, m::TransformedMesh) = TransformedMesh(m, t)

# special treatment for lists of geometries
applycoord(t::CoordinateTransform, g::StaticVector{<:Any,<:Geometry}) = map(gᵢ -> applycoord(t, gᵢ), g)
applycoord(t::CoordinateTransform, g::AbstractVector{<:Geometry}) = [applycoord(t, gᵢ) for gᵢ in g]
applycoord(t::CoordinateTransform, g::CircularVector{<:Geometry}) = CircularVector([applycoord(t, gᵢ) for gᵢ in g])

# ----------------
# IMPLEMENTATIONS
# ----------------

include("transforms/rotate.jl")
include("transforms/translate.jl")
include("transforms/scale.jl")
include("transforms/affine.jl")
include("transforms/stretch.jl")
include("transforms/stdcoords.jl")
include("transforms/proj.jl")
include("transforms/morphological.jl")
include("transforms/lengthunit.jl")
include("transforms/validcoords.jl")
include("transforms/shadow.jl")
include("transforms/slice.jl")
include("transforms/repair.jl")
include("transforms/bridge.jl")
include("transforms/smoothing.jl")

# --------------
# OPTIMIZATIONS
# --------------

function →(t₁::Rotate, t₂::Rotate)
  rot₁ = parameters(t₁).rot
  rot₂ = parameters(t₂).rot
  Rotate(rot₂ * rot₁)
end

function →(t₁::Translate, t₂::Translate)
  offsets₁ = parameters(t₁).offsets
  offsets₂ = parameters(t₂).offsets
  Translate(offsets₁ .+ offsets₂)
end

function →(t₁::Scale, t₂::Scale)
  factors₁ = parameters(t₁).factors
  factors₂ = parameters(t₂).factors
  Scale(factors₁ .* factors₂)
end

function →(t₁::Affine, t₂::Affine)
  A₁ = parameters(t₁).A
  A₂ = parameters(t₂).A
  b₁ = parameters(t₁).b
  b₂ = parameters(t₂).b
  Affine(A₂ * A₁, A₂ * b₁ + b₂)
end

function →(t₁::Stretch, t₂::Stretch)
  factors₁ = parameters(t₁).factors
  factors₂ = parameters(t₂).factors
  Stretch(factors₁ .* factors₂)
end

function →(t₁::Rotate, t₂::Translate)
  rot = parameters(t₁).rot
  offsets = parameters(t₂).offsets
  Affine(rot, SVector(offsets))
end
