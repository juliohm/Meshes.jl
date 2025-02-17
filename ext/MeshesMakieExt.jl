# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module MeshesMakieExt

using Meshes
using Unitful
using Rotations
using StaticArrays
using LinearAlgebra
using CoordRefSystems
using Colorfy

using Unitful: numtype
using Meshes: lentype
using CoordRefSystems: Projected

import TransformsBase as TB
import Makie.GeometryBasics as GB

import Meshes: viz, viz!
import Makie

Makie.@recipe(Viz, object) do scene
  Makie.Attributes(
    color=:slategray3,
    alpha=nothing,
    colormap=nothing,
    colorrange=nothing,
    showsegments=false,
    segmentcolor=:gray30,
    segmentsize=1.5,
    showpoints=false,
    pointmarker=:circle,
    pointcolor=:gray30,
    pointsize=4
  )
end

# choose between 2D and 3D axis
Makie.args_preferred_axis(g::Geometry) = embeddim(g) === 3 ? Makie.LScene : Makie.Axis
Makie.args_preferred_axis(d::Domain) = embeddim(d) === 3 ? Makie.LScene : Makie.Axis
Makie.args_preferred_axis(::AbstractVector{<:Vec{Dim}}) where {Dim} = Dim === 3 ? Makie.LScene : Makie.Axis

# color handling
include("colors.jl")

# utilities
include("utils.jl")

# viz recipes
include("mesh.jl")
include("grid.jl")
include("geometryset.jl")
include("subdomain.jl")
include("vector.jl")
include("fallbacks.jl")

end
