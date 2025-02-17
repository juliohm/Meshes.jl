# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function Makie.plot!(plot::Viz{<:Tuple{Grid}})
  grid = plot[:object]
  M = Makie.@lift manifold($grid)
  pdim = Makie.@lift paramdim($grid)
  edim = Makie.@lift embeddim($grid)
  vizgrid!(plot, M[], Val(pdim[]), Val(edim[]))
end

function vizgrid!(plot, ::Type{<:🌐}, pdim::Val, edim::Val)
  vizgrid!(plot, 𝔼, pdim, edim)
end

vizgrid!(plot, M::Type{<:𝔼}, pdim::Val, edim::Val) = vizgridfallback!(plot, M, pdim, edim)

function vizfacets!(plot::Viz{<:Tuple{Grid}})
  grid = plot[:object]
  M = Makie.@lift manifold($grid)
  pdim = Makie.@lift paramdim($grid)
  edim = Makie.@lift embeddim($grid)
  vizgridfacets!(plot, M[], Val(pdim[]), Val(edim[]))
end

vizgridfacets!(plot, M::Type, pdim::Val, edim::Val) = vizmeshfacets!(plot, M, pdim, edim)

# ----------------
# SPECIALIZATIONS
# ----------------

include("grid/cartesian.jl")
include("grid/rectilinear.jl")
include("grid/structured.jl")
include("grid/transformed.jl")

# -----------------
# HELPER FUNCTIONS
# -----------------

function vizgridfallback!(plot, M, pdim, edim)
  grid = plot[:object]
  color = plot[:color]
  alpha = plot[:alpha]
  colormap = plot[:colormap]
  colorrange = plot[:colorrange]
  showsegments = plot[:showsegments]

  # process color spec into colorant
  colorant = Makie.@lift process($color, $colormap, $colorrange, $alpha)

  colors = Makie.@lift begin
    if $colorant isa AbstractVector
      inds = _invalidinds($grid)
      [i ∈ inds ? Makie.Colors.coloralpha(c, 0) : c for (i, c) in enumerate($colorant)]
    else
      $colorant
    end
  end

  # number of vertices, elements and colors
  nverts = Makie.@lift nvertices($grid)
  nelems = Makie.@lift nelements($grid)
  ncolor = Makie.@lift $colorant isa AbstractVector ? length($colorant) : 1

  # visualize quadrangle mesh with texture using uv coords
  # plots with uv coords are always interpolated,
  # so it is only used in the case ncolor == nverts
  # or when there is a large number of elements
  if pdim == Val(2) && (ncolor[] == 1 || ncolor[] == nverts[] || nelems[] ≥ 1000)
    # decide whether or not to reverse connectivity list
    rfunc = Makie.@lift _reverse($grid)

    verts = Makie.@lift map(asmakie, eachvertex($grid))
    quads = Makie.@lift [GB.QuadFace($rfunc(indices(e))) for e in elements(topology($grid))]

    dims = Makie.@lift size($grid)
    vdims = Makie.@lift Meshes.vsize($grid)
    texture = if ncolor[] == 1
      Makie.@lift fill($colors, $dims)
    elseif ncolor[] == nelems[]
      Makie.@lift reshape($colors, $dims)
    elseif ncolor[] == nverts[]
      Makie.@lift reshape($colors, $vdims)
    else
      throw(ArgumentError("invalid number of colors"))
    end

    uv = Makie.@lift [Makie.Vec2f(v, 1 - u) for v in range(0, 1, $vdims[2]) for u in range(0, 1, $vdims[1])]

    mesh = Makie.@lift GB.Mesh($verts, $quads, uv=$uv)

    shading = edim == Val(3) ? Makie.FastShading : Makie.NoShading

    Makie.mesh!(plot, mesh, color=texture, shading=shading)

    if showsegments[]
      vizfacets!(plot)
    end
  else # fallback to triangle mesh visualization
    vizmesh!(plot, M, pdim, edim)
  end
end

_reverse(grid) = crs(grid) <: LatLon && orientation(first(grid)) == CW ? reverse : identity

function _invalidinds(grid)
  if crs(grid) <: Projected && (grid isa RegularGrid || (grid isa TransformedGrid && parent(grid) isa RegularGrid))
    tgrid = grid |> Proj(LatLon)

    dims = size(tgrid)
    topo = topology(tgrid)
    sx, sy = dims
    B = Boundary{2,0}(topo)

    lon(i) = coords(vertex(tgrid, i)).lon
    function isinvalid(e)
      is = B(e)
      lon(is[1]) > lon(is[3])
    end

    inds = Int[]
    linds = LinearIndices(dims)
    for i in 1:sx
      e = linds[i, 1]
      if isinvalid(e)
        push!(inds, e)
      end
    end

    # @info inds

    if !isempty(inds)
      A = Adjacency{2}(topo)
      while true
        e = last(inds)
        es = setdiff(A(e), inds)
        i = findfirst(isinvalid, es)
        if isnothing(i)
          break
        else
          push!(inds, es[i])
          # @info inds
        end
      end
      inds
    else
      Int[]
    end
  else
    Int[]
  end
end

# helper functions to create a minimum number
# of line segments within Cartesian/Rectilinear grid
function xysegments(xs, ys)
  coords = []
  for x in xs
    push!(coords, (x, first(ys)))
    push!(coords, (x, last(ys)))
    push!(coords, (NaN, NaN))
  end
  for y in ys
    push!(coords, (first(xs), y))
    push!(coords, (last(xs), y))
    push!(coords, (NaN, NaN))
  end
  x = getindex.(coords, 1)
  y = getindex.(coords, 2)
  x, y
end

function xyzsegments(xs, ys, zs)
  coords = []
  for y in ys, z in zs
    push!(coords, (first(xs), y, z))
    push!(coords, (last(xs), y, z))
    push!(coords, (NaN, NaN, NaN))
  end
  for x in xs, z in zs
    push!(coords, (x, first(ys), z))
    push!(coords, (x, last(ys), z))
    push!(coords, (NaN, NaN, NaN))
  end
  for x in xs, y in ys
    push!(coords, (x, y, first(zs)))
    push!(coords, (x, y, last(zs)))
    push!(coords, (NaN, NaN, NaN))
  end
  x = getindex.(coords, 1)
  y = getindex.(coords, 2)
  z = getindex.(coords, 3)
  x, y, z
end
