# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function vizgrid2D!(plot::Viz{<:Tuple{StructuredGrid}})
  grid = plot[:object]
  color = plot[:color]
  alpha = plot[:alpha]
  colormap = plot[:colormap]
  colorrange = plot[:colorrange]
  showsegments = plot[:showsegments]
  segmentcolor = plot[:segmentcolor]
  segmentsize = plot[:segmentsize]

  # process color spec into colorant
  colorant = Makie.@lift process($color, $colormap, $colorrange, $alpha)

  # number of vertices and colors
  nv = Makie.@lift nvertices($grid)
  nc = Makie.@lift $colorant isa AbstractVector ? length($colorant) : 1

  if nc[] == nv[]
    # size and coordinates
    sz = Makie.@lift size($grid) .+ 1
    XYZ = Makie.@lift Meshes.XYZ($grid)
    X = Makie.@lift $XYZ[1]
    Y = Makie.@lift $XYZ[2]

    # visualize as built-in surface
    C = Makie.@lift reshape($colorant, $sz)
    Makie.surface!(plot, X, Y, color=C)

    # visualize segments
    tup = Makie.@lift structuredsegments($grid)
    x, y = Makie.@lift($tup[1]), Makie.@lift($tup[2])
    segplot = Makie.lines!(plot, x, y, color=segmentcolor, linewidth=segmentsize)
    segplot.visible = showsegments
  else
    vizmesh2D!(plot)
  end
end

function structuredsegments(grid)
  cinds = CartesianIndices(size(grid) .+ 1)
  coords = []
  # vertical segments
  for j in axes(cinds, 2)
    for i in axes(cinds, 1)
      p = vertex(grid, cinds[i, j])
      c = Tuple(coordinates(p))
      push!(coords, c)
    end
    push!(coords, (NaN, NaN))
  end
  # horizontal segments
  for i in axes(cinds, 1)
    for j in axes(cinds, 2)
      p = vertex(grid, cinds[i, j])
      c = Tuple(coordinates(p))
      push!(coords, c)
    end
    push!(coords, (NaN, NaN))
  end
  x = getindex.(coords, 1)
  y = getindex.(coords, 2)
  x, y
end
