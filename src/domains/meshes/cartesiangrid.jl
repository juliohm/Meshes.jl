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
const CartesianGrid{M<:𝔼,C<:Cartesian} = RegularGrid{M,C}

function CartesianGrid(
  origin::Point{<:𝔼},
  spacing::NTuple{Dim,ℒ},
  offset::Dims{Dim},
  topology::GridTopology{Dim}
) where {Dim,ℒ<:Len}
  orig = Point(convert(Cartesian, coords(origin)))
  RegularGrid(orig, spacing, offset, topology)
end

CartesianGrid(
  origin::Point{<:𝔼},
  spacing::NTuple{Dim,Len},
  offset::Dims{Dim},
  topology::GridTopology{Dim}
) where {Dim} = CartesianGrid(origin, promote(spacing...), offset, topology)

CartesianGrid(
  origin::Point{<:𝔼},
  spacing::NTuple{Dim,Number},
  offset::Dims{Dim},
  topology::GridTopology{Dim}
) where {Dim} = CartesianGrid(origin, addunit.(spacing, u"m"), offset, topology)

function CartesianGrid(
  dims::Dims{Dim},
  origin::Point,
  spacing::NTuple{Dim,Number},
  offset::Dims{Dim}=ntuple(i -> 1, Dim)
) where {Dim}
  if !all(>(0), dims)
    throw(ArgumentError("dimensions must be positive"))
  end
  CartesianGrid(origin, spacing, offset, GridTopology(dims))
end

CartesianGrid(
  dims::Dims{Dim},
  origin::NTuple{Dim,Number},
  spacing::NTuple{Dim,Number},
  offset::Dims{Dim}=ntuple(i -> 1, Dim)
) where {Dim} = CartesianGrid(dims, Point(origin), spacing, offset)

function CartesianGrid(start::Point, finish::Point, spacing::NTuple{Dim,ℒ}) where {Dim,ℒ<:Len}
  dims = Tuple(ceil.(Int, (finish - start) ./ spacing))
  origin = start
  offset = ntuple(i -> 1, Dim)
  CartesianGrid(dims, origin, spacing, offset)
end

CartesianGrid(start::Point, finish::Point, spacing::NTuple{Dim,Len}) where {Dim} =
  CartesianGrid(start, finish, promote(spacing...))

CartesianGrid(start::Point, finish::Point, spacing::NTuple{Dim,Number}) where {Dim} =
  CartesianGrid(start, finish, addunit.(spacing, u"m"))

CartesianGrid(start::NTuple{Dim,Number}, finish::NTuple{Dim,Number}, spacing::NTuple{Dim,Number}) where {Dim} =
  CartesianGrid(Point(start), Point(finish), spacing)

function CartesianGrid(start::Point, finish::Point; dims::Dims=ntuple(i -> 100, embeddim(start)))
  origin = start
  spacing = Tuple((finish - start) ./ dims)
  offset = ntuple(i -> 1, length(dims))
  CartesianGrid(dims, origin, spacing, offset)
end

CartesianGrid(
  start::NTuple{Dim,Number},
  finish::NTuple{Dim,Number};
  dims::Dims{Dim}=ntuple(i -> 100, Dim)
) where {Dim} = CartesianGrid(Point(start), Point(finish); dims)

function CartesianGrid(dims::Dims{Dim}) where {Dim}
  origin = ntuple(i -> 0.0, Dim)
  spacing = ntuple(i -> 1.0, Dim)
  offset = ntuple(i -> 1, Dim)
  CartesianGrid(dims, origin, spacing, offset)
end

CartesianGrid(dims::Int...) = CartesianGrid(dims)
