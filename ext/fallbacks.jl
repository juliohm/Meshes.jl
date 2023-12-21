# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

Makie.plottype(::AbstractVector{<:Geometry}) = Viz{<:Tuple{AbstractVector{<:Geometry}}}

Makie.convert_arguments(::Type{<:Viz}, geoms::AbstractVector{<:Geometry}) = (GeometrySet(geoms),)

Makie.plottype(::Geometry) = Viz{<:Tuple{Geometry}}

Makie.convert_arguments(::Type{<:Viz}, geom::Geometry) = (GeometrySet([geom]),)

Makie.plottype(::Domain) = Viz{<:Tuple{Domain}}

Makie.convert_arguments(::Type{<:Viz}, domain::Domain) = (GeometrySet(collect(domain)),)

Makie.plottype(::Mesh) = Viz{<:Tuple{Mesh}}

Makie.convert_arguments(::Type{<:Viz}, mesh::Mesh) = (convert(SimpleMesh, mesh),)

# skip conversion for these types
Makie.convert_arguments(::Type{<:Viz}, gset::GeometrySet) = (gset,)
Makie.convert_arguments(::Type{<:Viz}, mesh::SimpleMesh) = (mesh,)
Makie.convert_arguments(::Type{<:Viz}, grid::CartesianGrid) = (grid,)
Makie.convert_arguments(::Type{<:Viz}, grid::SubCartesianGrid) = (grid,)
