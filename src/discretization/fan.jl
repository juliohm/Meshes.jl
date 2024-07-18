# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    FanTriangulation()

The fan triangulation algorithm for convex polygons.
See [https://en.wikipedia.org/wiki/Fan_triangulation]
(https://en.wikipedia.org/wiki/Fan_triangulation).
"""
struct FanTriangulation <: BoundaryDiscretizationMethod end

_discretizewithin(ring::Ring, ::Val{2}, ::FanTriangulation) = fan(ring)

_discretizewithin(ring::Ring, ::Val{3}, ::FanTriangulation) = fan(ring)

function fan(ring::Ring)
  points = collect(vertices(ring))
  connec = [connect((1, i, i + 1)) for i in 2:(nvertices(ring) - 1)]
  SimpleMesh(points, connec)
end
