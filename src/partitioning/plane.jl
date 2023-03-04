# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    PlanePartition(normal; tol=1e-6)

A method for partitioning spatial objects into a family of hyperplanes
defined by a `normal` direction. Two points `x` and `y` belong to the same
hyperplane when `(x - y) ⋅ normal < tol`.
"""
struct PlanePartition{Dim,T} <: SPredicatePartitionMethod
  normal::Vec{Dim,T}
  tol::Float64

  function PlanePartition{Dim,T}(normal, tol) where {Dim,T}
    return new(normalize(normal), tol)
  end
end

function PlanePartition(normal::Vec{Dim,T}; tol=1e-6) where {Dim,T}
  return PlanePartition{Dim,T}(normal, tol)
end

function PlanePartition(normal::NTuple{Dim,T}, ; tol=1e-6) where {Dim,T}
  return PlanePartition(Vec(normal); tol=tol)
end

(p::PlanePartition)(x, y) = abs((x - y) ⋅ p.normal) < p.tol
