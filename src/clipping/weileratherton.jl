# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    WeilerAthertonClipping()

The Wieler-Atherton algorithm for clipping polygons.

## References

* Weiler, K., & Atherton, P. 1977. [Hidden surface removal using polygon area sorting]
  (https://dl.acm.org/doi/pdf/10.1145/563858.563896)
"""
struct WeilerAthertonClipping <: ClippingMethod end

# VertexType distinguishes three different types of vertices used for constructing the structure
# used by the Weiler-Atherton clipping algorithm. Normal type represents regular vertices, the
# connecting points of edges of a rings. Entering and Exiting types represent intersections of
# two ring edges, where one belongs to a clipping and other belongs to a clipped ring. The
# Entering and Exiting types describe, from the perspective of the edges of the clipping ring,
# whether it enters or exits the interior of the clipped ring.
abstract type VertexType end
abstract type Normal <: VertexType end
abstract type Entering <: VertexType end
abstract type Exiting <: VertexType end

# Data structure for clipping the polygons. Fields left and right are used depending on the
# VertexType, as designated with the helper functions. The data structure forms a directed
# graph with each element always pointing to two elements.
mutable struct RingVertex{VT<:VertexType,P<:Point}
  point::P
  left::RingVertex{<:VertexType,P}
  right::RingVertex{<:VertexType,P}

  function RingVertex{VT,P}(point) where {VT<:VertexType,P<:Point}
    v = new(point)
    v.left = v
    v.right = v
    v
  end
end

RingVertex{VT}(point::P) where {VT<:VertexType,P<:Point} = RingVertex{VT,P}(point)

isnormal(::RingVertex{Normal}) = true
isnormal(::RingVertex) = false

isentering(::RingVertex{Entering}) = true
isentering(::RingVertex) = false

function appendvertices!(v₁::RingVertex{Normal}, v₂::RingVertex{Normal})
  v₂.left = v₁.left
  v₁.left = v₂
  v₂.right = v₁.right
  v₁.right = v₂
end

# Helper functions to designate the use of the left and right branches of the RingVertex.

# Normal vertex uses the left branch for the next Normal vertex,
# which is the end of the ring edge for which the current vertex is the edge start.
nextnormal(v::RingVertex{Normal}) = v.left
# Normal vertex uses the right branch for the next intersection on the ring edge if any.
# Otherwise, it holds the next Normal vertex, same as for the left branch.
nextvertex(v::RingVertex{Normal}) = v.right
# Next clipping vertex is a following vertex, normal or an intersection, on a clipping ring.
# Next clipped vertex is a following vertex, normal or an intersection, on a clipped ring.
# Normal vertices are either on a clipping or a clipped, but the implementation is same
# and helper functions can be used interchangeably.
getnextclippingvertex(v::RingVertex{Normal}) = v.right
setnextclippingvertex!(v::RingVertex{Normal}, next::RingVertex) = v.right = next
getnextclippedvertex(v::RingVertex{Normal}) = v.right
setnextclippedvertex!(v::RingVertex{Normal}, next::RingVertex) = v.right = next

# Both Entering and Exiting vertices are always intersections and use the left branch for
# the following vertex on the clipping ring.
getnextclippingvertex(v::RingVertex) = v.left
setnextclippingvertex!(v::RingVertex, next::RingVertex) = v.left = next

# Similarly, the right branch holds the following vertex on the clipped ring.
getnextclippedvertex(v::RingVertex) = v.right
setnextclippedvertex!(v::RingVertex, next::RingVertex) = v.right = next

# Traversing and selecting correct following vertices from the directed graph of RingVertex
# elements should switch between rings whenever an intersection is encountered. If the current
# edge is entering the interior of the clipped ring, follow to the next vertex on the clipping
# ring. In case the edge is exiting the interior of the clipped ring, then follow the next vertex
# on the clipped ring. For a Normal vertex take the next vertex which can be either an intersection
# or an edge end.
getnextresultvertex(v::RingVertex{Normal}) = nextvertex(v)
getnextresultvertex(v::RingVertex{Entering}) = getnextclippedvertex(v)
getnextresultvertex(v::RingVertex{Exiting}) = getnextclippingvertex(v)

function clip(poly::Polygon, ring::Ring, ::WeilerAthertonClipping)
  polyrings = rings(poly)

  # If the polygon is contained in the ring, return the polygon right away.
  allcontained = all(v ∈ PolyArea(ring) for v in vertices(polyrings[1]))
  if (orientation(ring) == CCW && allcontained)
    return poly
  end

  # Convert the subject polygon rings and the clipping ring to the RingVertex data structure.
  clippedrings = [gettraversalring(r) for r in polyrings]
  clipping = gettraversalring(ring)

  # For keeping track of intersected rings, as the non-intersected ones need additional
  # processing at the end.
  intersected = zeros(Bool, length(clippedrings))

  # For marking of clipping ring vertices which touch rings of clipped polygon.
  clippingtouches = zeros(Bool, nvertices(ring))

  # For collecting all entering vertices, as they are used as starting points for collection
  # of the output rings.
  entering = RingVertex{Entering}[]

  for l in 1:nvertices(ring)
    # Three consecutive clipping vertices are used to properly identify intersection vertex type
    # for corner cases, so the clipping segment is constructed with the two following vertices
    # after the current one.
    clippingedgestart = nextnormal(clipping)
    clippingedgeend = nextnormal(clippingedgestart)
    clippingsegment = Segment(clippingedgestart.point, clippingedgeend.point)

    for (k, clipped) in enumerate(clippedrings)
      for _ in 1:nvertices(polyrings[k])
        # Like for the clipping, the clipped also uses three consecutive vertices.
        clippededgestart = nextnormal(clipped)
        clippededgeend = nextnormal(clippededgestart)
        clippedsegment = Segment(clippededgestart.point, clippededgeend.point)

        I = intersection(clippingsegment, clippedsegment)

        if type(I) != NotIntersecting
          vertices = vertexfromintersection(I, clipping, clipped)
          if !isnothing(vertices)
            insertintersections!(vertices, clippingedgestart, clippededgestart, entering)
            intersected[k] = true
          elseif type(I) in [EdgeTouching, CornerTouching] && get(I) ≈ clippingedgestart.point
            clippingtouches[l] = true
          end
        end

        clipped = nextnormal(clipped)
      end
    end

    clipping = nextnormal(clipping)
  end

  if !any(intersected)
    # Handle the case when no interections have been found.
    if orientation(ring) == CW
      # For an inner clipping ring take all clipped rings outside of it.
      return PolyArea(collectoutsiderings(ring, polyrings)...)
    else
      # Align the clippingtouches with the ring vertices.
      clippingtouches = [clippingtouches[end], clippingtouches[1:(end - 1)]...]
      # For an outer clipping ring add it to act as the outer ring of the clipped ring.
      collectedrings =
        all(t || v ∈ PolyArea(polyrings[1]) for (t, v) in zip(clippingtouches, vertices(ring))) ? [ring] : []
    end
  else
    # Collect rings formed from the intersected rings.
    collectedrings = collectclipped(entering)
  end

  # Complete the collected rings by adding non-intersected rings
  # if they are contained within the collected ones.
  completedrings = [perhapsaddnonintersected!(r, polyrings, intersected) for r in collectedrings]

  # Convert completed ring lists into PolyAreas.
  polys = PolyArea.(filter(!isnothing, completedrings))

  n = length(polys)
  n == 0 ? nothing : (n == 1 ? polys[1] : Multi(polys))
end

clip(poly::Polygon, other::Geometry, method::WeilerAthertonClipping) = clip(poly, boundary(other), method)

function collectoutsiderings(ring, polyrings)
  newpolyrings = Ring[]
  for k in eachindex(polyrings)
    if !all(v ∈ PolyArea(ring) for v in vertices(polyrings[k]))
      push!(newpolyrings, polyrings[k])
    end
  end
  if any(v ∈ PolyArea(polyrings[1]) for v in vertices(ring))
    push!(newpolyrings, ring)
  end
  newpolyrings
end

function perhapsaddnonintersected!(ring, polyrings, intersected)
  # Handle all the non-intersected rings. Add them if they are contained in the clipping ring.
  newpolyrings = [ring]
  for k in eachindex(intersected)
    if !intersected[k]
      ccw = orientation(ring) == CCW

      # Discard if the processed ring is an outer ring but inside another inner ring.
      if ccw && vertices(ring)[1] ∈ PolyArea(polyrings[k]) && k > 1
        return nothing
      end

      vs = vertices(polyrings[k])
      ins = count(v ∈ PolyArea(ring) for v in vs)
      outs = length(vs) - ins
      if ccw == (ins > outs)
        if !ccw
          # An outer ring should be first in the list.
          pushfirst!(newpolyrings, polyrings[k])
        else
          # Inner rings should follow an outer in the list.
          push!(newpolyrings, polyrings[k])
        end
        intersected[k] = true
      end
    end
  end
  newpolyrings
end

function insertintersection!(head::RingVertex{Normal}, intersection::RingVertex, getnext, setnext!)
  tail = nextnormal(head)
  current = head
  newdistance = measure(Segment(head.point, intersection.point))
  # Search for the place to insert the intersection by comparing its distance
  # from the head with other inserted intersections.
  while true
    before = current
    current = getnext(current)
    currentdistance = measure(Segment(head.point, current.point))

    if (newdistance < currentdistance) || (current == tail)
      setnext!(intersection, current)
      setnext!(before, intersection)
      break
    end
  end
end

insertintersections!(_::Nothing, _, _, _) = nothing

# Inserts the intersection into both the clipping and the clipped rings.
function insertintersections!(vertex::RingVertex, clipping::RingVertex{Normal}, clipped::RingVertex{Normal}, entering)
  insertintersection!(clipping, vertex, getnextclippingvertex, setnextclippingvertex!)
  insertintersection!(clipped, vertex, getnextclippedvertex, setnextclippedvertex!)

  if isentering(vertex)
    push!(entering, vertex)
  end
end

insertintersections!(vertices::Array, clipping, clipped, entering) =
  insertintersections!.(vertices, Ref(clipping), Ref(clipped), Ref(entering))

# Takes a list of entering vertices and returns all rings that contain those vertices.
function collectclipped(entering::Vector{RingVertex{Entering}})
  rings = Ring[]
  visited = RingVertex[]
  for i in eachindex(entering)
    if entering[i] in visited
      continue
    end

    ring = RingVertex[]
    vertex = entering[i]
    while !(vertex in ring)
      if vertex in visited
        break
      end

      nextvertex = getnextresultvertex(vertex)
      # Skip adding sequential duplicates, and sequential entering vertices
      # which can happen with overlapping edge intersections.
      if !(isentering(vertex) && isentering(nextvertex)) && !(vertex.point ≈ nextvertex.point)
        push!(ring, vertex)
      end
      push!(visited, vertex)
      vertex = nextvertex
    end

    if length(ring) > 2
      push!(rings, Ring([r.point for r in ring]))
    end
  end
  rings
end

function vertexfromintersection(I, clipping, clipped)
  type(I) == Crossing && return vertexfromcrossing(get(I), clipping, clipped)
  type(I) == CornerTouching && return vertexfromcornertouching(get(I), clipping, clipped)
  type(I) == EdgeTouching && return vertexfromedgetouching(get(I), clipping, clipped)
  type(I) == Overlapping && return vertexfromoverlapping(get(I), clipping, clipped)
  @assert false # No other intersection types expected.
end

function vertexfromcrossing(point, clipping, clipped)
  cl = Line(nextnormal(clipping).point, nextnormal(nextnormal(clipping)).point)
  vertextype = sideof(nextnormal(nextnormal(clipped)).point, cl) == LEFT ? Entering : Exiting
  RingVertex{vertextype}(point)
end

function vertexfromedgetouching(point, clipping, clipped)
  vertextype = nothing
  if point ≈ nextnormal(clipped).point
    # When intersection is at the shared vertex of two edges of the clipped ring,
    # then split the intersecting edge of the clipping ring at the intersection point.
    vertextype = decidedirection(
      Segment(clipped.point, nextnormal(clipped).point),
      Segment(nextnormal(clipped).point, nextnormal(nextnormal(clipped)).point),
      Segment(nextnormal(clipping).point, point),
      Segment(point, nextnormal(nextnormal(clipping)).point)
    )
  elseif point ≈ nextnormal(clipping).point
    # When intersection is at the shared vertex of two edges of the clipping ring,
    # then split the intersecting edge of the clipped ring at the intersection point.
    vertextype = decidedirection(
      Segment(nextnormal(clipped).point, point),
      Segment(point, nextnormal(nextnormal(clipped)).point),
      Segment(clipping.point, nextnormal(clipping).point),
      Segment(nextnormal(clipping).point, nextnormal(nextnormal(clipping)).point)
    )
  end
  isnothing(vertextype) ? nothing : RingVertex{vertextype}(point)
end

function vertexfromcornertouching(point, clipping, clipped)
  vertextype = nothing
  # When intersection is at the shared vertices of both the clipping and the clipped rings.
  if (point ≈ nextnormal(clipped).point) && (point ≈ nextnormal(clipping).point)
    # Only applies if the intersection coincides with the middles of the currently observed
    # vertices for both clipping and clipped rings.
    vertextype = decidedirection(
      Segment(clipped.point, point),
      Segment(point, nextnormal(nextnormal(clipped)).point),
      Segment(clipping.point, point),
      Segment(point, nextnormal(nextnormal(clipping)).point)
    )
  end
  isnothing(vertextype) ? nothing : RingVertex{vertextype}(point)
end

function vertexfromoverlapping(segment, clipping, clipped)
  # For both ends of the intersecting segment, check if it coincides with the middle of
  # the observed vertices for clipped and clipping rings. If it does, attempt adding a
  # point.

  ret = RingVertex[]
  for point in extrema(segment)
    if point ≈ nextnormal(clipped).point
      clippingprev = Segment(nextnormal(clipping).point, point)
      if measure(clippingprev) ≈ 0.0u"m"
        clippingprev = Segment(clipping.point, point)
      end
      vertextype = decidedirection(
        Segment(clipped.point, point),
        Segment(point, nextnormal(nextnormal(clipped)).point),
        clippingprev,
        Segment(point, nextnormal(nextnormal(clipping)).point)
      )
      if !isnothing(vertextype)
        push!(ret, RingVertex{vertextype}(point))
      end
    end

    if point ≈ nextnormal(clipping).point
      clippedprev = Segment(nextnormal(clipped).point, point)
      if measure(clippedprev) ≈ 0.0u"m"
        clippedprev = Segment(clipped.point, point)
      end
      vertextype = decidedirection(
        clippedprev,
        Segment(point, nextnormal(nextnormal(clipped)).point),
        Segment(clipping.point, point),
        Segment(point, nextnormal(nextnormal(clipping)).point)
      )
      if !isnothing(vertextype)
        push!(ret, RingVertex{vertextype}(point))
      end
    end
  end
  (length(ret) == 0) ? nothing : ret
end

# Used to figure out the type of the vertex to add when intersection is other than the crossing
# type. For input it takes four segments which all overlap on a single central vertex.
# Function measures the angles formed between the segments and checks wether the two clipped segments
# start and end in the same region or different regions, as separated by the clipping segments.
function decidedirection(clipped₁, clipped₂, clipping₁, clipping₂)
  T = numtype(lentype(clipped₁))

  # The input segments should all share one common vertex.
  # Form vectors from the common vertex to other vertices.
  a = minimum(clipped₁) - maximum(clipped₁)
  b = maximum(clipped₂) - minimum(clipped₂)
  c = minimum(clipping₁) - maximum(clipping₁)
  d = maximum(clipping₂) - minimum(clipping₂)

  if any(norm(v) ≈ 0.0u"m" for v in (a, b, c, d))
    # An zero length input segment found, no need to calculate.
    return nothing
  end

  tol = atol(0.0) * u"rad"
  twoπ = 2 * T(π) * u"rad"

  β = mod(∠(a, b), twoπ)
  γ = mod(∠(a, c), twoπ)
  δ = mod(∠(a, d), twoπ)

  if isapproxzero(γ, atol=tol) || isapprox(γ, twoπ, atol=tol)
    if δ < β < twoπ
      return Entering
    else
      return Exiting
    end
  elseif isapproxzero(δ, atol=tol) || isapprox(δ, twoπ, atol=tol)
    if γ < β < twoπ
      return Exiting
    else
      return Entering
    end
  end

  if γ < δ && (γ < β || isapprox(β, γ, atol=tol)) && (isapprox(β, δ, atol=tol) || β < δ)
    return Exiting
  elseif δ < γ && (δ < β || isapprox(β, δ, atol=tol)) && (isapprox(β, γ, atol=tol) || β < γ)
    return Entering
  end

  nothing
end

# Converts a regular Meshes.Ring into a ring formed with RingVertex data type.
function gettraversalring(ring::Ring)
  vs = vertices(ring)
  start = RingVertex{Normal}(vs[1])

  for v in vs[2:end]
    new = RingVertex{Normal}(v)
    appendvertices!(start, new)
    start = new
  end

  return nextnormal(start)
end
