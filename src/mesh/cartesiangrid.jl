# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    CartesianGrid(dims, origin, spacing)

A Cartesian grid with dimensions `dims`, lower left corner at `origin`
and cell spacing `spacing`. The three arguments must have the same length.

    CartesianGrid(dims, origin, spacing, offset)

A Cartesian grid with dimensions `dims`, with lower left corner of element
`offset` at `origin` and cell spacing `spacing`.

    CartesianGrid(start, finish, dims=dims)

Alternatively, construct a Cartesian grid from a `start` point (lower left)
to a `finish` point (upper right).

    CartesianGrid(start, finish, spacing)

Alternatively, construct a Cartesian grid from a `start` point to a `finish`
point using a given `spacing`.

    CartesianGrid(dims)
    CartesianGrid(dim1, dim2, ...)

Finally, a Cartesian grid can be constructed by only passing the dimensions
`dims` as a tuple, or by passing each dimension `dim1`, `dim2`, ... separately.
In this case, the origin and spacing default to (0,0,...) and (1,1,...).

## Examples

Create a 3D grid with 100x100x50 hexahedrons:

```julia
julia> CartesianGrid(100, 100, 50)
```

Create a 2D grid with 100 x 100 quadrangles and origin at (10.0, 20.0):

```julia
julia> CartesianGrid((100, 100), (10.0, 20.0), (1.0, 1.0))
```

Create a 1D grid from -1 to 1 with 100 segments:

```julia
julia> CartesianGrid((-1.0,), (1.0,), dims=(100,))
```
"""
struct CartesianGrid{Dim,P<:Point{Dim},L<:Len} <: Grid{Dim}
  origin::P
  spacing::NTuple{Dim,L}
  offset::Dims{Dim}
  topology::GridTopology{Dim}

  function CartesianGrid(
    origin::P,
    spacing::NTuple{Dim,L},
    offset::Dims{Dim},
    topology::GridTopology{Dim}
  ) where {Dim,P<:Point{Dim},L<:Len}
    if !all(>(zero(L)), spacing)
      throw(ArgumentError("spacing must be positive"))
    end
    new{Dim,P,float(L)}(origin, spacing, offset, topology)
  end
end

CartesianGrid(origin::Point{Dim}, spacing::NTuple{Dim}, offset::Dims{Dim}, topology::GridTopology{Dim}) where {Dim} =
  CartesianGrid(origin, addunit.(spacing, u"m"), offset, topology)

function CartesianGrid(
  dims::Dims{Dim},
  origin::Point{Dim},
  spacing::NTuple{Dim},
  offset::Dims{Dim}=ntuple(i -> 1, Dim)
) where {Dim}
  if !all(>(0), dims)
    throw(ArgumentError("dimensions must be positive"))
  end
  CartesianGrid(origin, spacing, offset, GridTopology(dims))
end

CartesianGrid(
  dims::Dims{Dim},
  origin::NTuple{Dim},
  spacing::NTuple{Dim},
  offset::Dims{Dim}=ntuple(i -> 1, Dim)
) where {Dim} = CartesianGrid(dims, Point(origin), spacing, offset)

function CartesianGrid(start::Point{Dim}, finish::Point{Dim}, spacing::NTuple{Dim,L}) where {Dim,L<:Len}
  dims = Tuple(ceil.(Int, (finish - start) ./ spacing))
  origin = start
  offset = ntuple(i -> 1, Dim)
  CartesianGrid(dims, origin, spacing, offset)
end

CartesianGrid(start::Point{Dim}, finish::Point{Dim}, spacing::NTuple{Dim}) where {Dim} =
  CartesianGrid(start, finish, addunit.(spacing, u"m"))

CartesianGrid(start::NTuple{Dim}, finish::NTuple{Dim}, spacing::NTuple{Dim}) where {Dim} =
  CartesianGrid(Point(start), Point(finish), spacing)

function CartesianGrid(start::Point{Dim}, finish::Point{Dim}; dims::Dims{Dim}=ntuple(i -> 100, Dim)) where {Dim}
  origin = start
  spacing = Tuple((finish - start) ./ dims)
  offset = ntuple(i -> 1, Dim)
  CartesianGrid(dims, origin, spacing, offset)
end

CartesianGrid(start::NTuple{Dim}, finish::NTuple{Dim}; dims::Dims{Dim}=ntuple(i -> 100, Dim)) where {Dim} =
  CartesianGrid(Point(start), Point(finish); dims)

function CartesianGrid(dims::Dims{Dim}) where {Dim}
  origin = ntuple(i -> 0.0, Dim)
  spacing = ntuple(i -> 1.0, Dim)
  offset = ntuple(i -> 1, Dim)
  CartesianGrid(dims, origin, spacing, offset)
end

CartesianGrid(dims::Int...) = CartesianGrid(dims)

vertex(g::CartesianGrid{Dim}, ijk::Dims{Dim}) where {Dim} = g.origin + Vec((ijk .- g.offset) .* g.spacing)

spacing(g::CartesianGrid) = g.spacing

offset(g::CartesianGrid) = g.offset

function xyz(g::CartesianGrid{Dim}) where {Dim}
  dims = size(g)
  spac = spacing(g)
  orig = coordinates(minimum(g))
  ntuple(Dim) do i
    o, s, d = orig[i], spac[i], dims[i]
    range(start=o, step=s, length=(d + 1))
  end
end

XYZ(g::CartesianGrid) = XYZ(xyz(g))

function centroid(g::CartesianGrid, ind::Int)
  ijk = elem2cart(topology(g), ind)
  p = vertex(g, ijk)
  δ = Vec(spacing(g) ./ 2)
  p + δ
end

function Base.getindex(g::CartesianGrid{Dim}, I::CartesianIndices{Dim}) where {Dim}
  @boundscheck _checkbounds(g, I)
  dims = size(I)
  offset = g.offset .- Tuple(first(I)) .+ 1
  CartesianGrid(dims, g.origin, g.spacing, offset)
end

==(g1::CartesianGrid, g2::CartesianGrid) =
  g1.topology == g2.topology &&
  g1.spacing == g2.spacing &&
  Tuple(g1.origin - g2.origin) == (g1.offset .- g2.offset) .* g1.spacing

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, g::CartesianGrid)
  dims = join(size(g.topology), "×")
  print(io, "$dims CartesianGrid")
end

Base.show(io::IO, g::CartesianGrid) = summary(io, g)

function Base.show(io::IO, ::MIME"text/plain", g::CartesianGrid)
  println(io, g)
  println(io, "├─ minimum: ", minimum(g))
  println(io, "├─ maximum: ", maximum(g))
  print(io, "└─ spacing: ", spacing(g))
end
