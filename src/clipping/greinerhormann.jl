# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GreinerHormannClipping()

The Greiner-Hormann algorithm for clipping polygons.

## References

* Greiner, G. & Hormann, K. 1998. [Efficient Clipping of Arbitrary Polygons]
  (https://dl.acm.org/doi/pdf/10.1145/274363.274364)

### Notes

* The Algorithm applies to any arbitrary polygon.
"""


@enum IntersectionLabel begin
  na
  crossing
  bouncing
  left_on
  right_on
  on_on
  on_left
  on_right
  delayed_crossing
  delayed_bouncing
end

@enum RelativePositionType begin
  left
  right
  is_pm
  is_pp
end

@enum EntryExit begin
  exit
  entry
  neither
end

struct GreinerHormannClipping <: ClippingMethod end

mutable struct GreinerVertex
  coords::Point
  prev::Int # this should point to previous vertex
  next::Int # point to next vert
  neighbour::Int # point to neighbour vertex for intersection
  source::Bool
  intersection::Bool
  alpha::Float64
  label::IntersectionLabel
  enex::EntryExit

  GreinerVertex(coords::Point, prev::Int, next::Int, neighbour::Int, source::Bool, intersection::Bool, alpha::Float64, label::IntersectionLabel, enex::EntryExit) = new(
    coords,
    prev,
    next,
    neighbour,
    source,
    intersection,
    alpha,
    label,
    enex
  )

  GreinerVertex() = new(
    Point((0, 0)),
    1,
    1,
    1,
    false,
    false,
    -1.0,
    IntersectionLabel(0),
    EntryExit(2)
  )
end

function GreinerVertex(coords::Point)
  GreinerVertex(coords, 1, 1, 1, false, false, -1.0, IntersectionLabel(0), EntryExit(2))
end



function GreinerVertex(ring::T) where {T<:Ring}
  verts = vertices(ring)
  ringₜ = Vector{GreinerVertex}()
  ringₜ = _newVertex!(ringₜ, verts[1], true)
  for i in 2:length(verts)
    prev_index = i == 1 ? length(verts) : i - 1
    next_index = i == length(verts) ? 1 : i + 1
    _newVertex!(ringₜ, verts[i], false)
  end
  ringₜ

end

_getneighbor(v::GreinerVertex) = v.neighbour
_getprev(v::GreinerVertex) = v.prev
_getnext(v::GreinerVertex) = v.next
coords(v::GreinerVertex) = v.coords
_getenex(v::GreinerVertex) = v.enex

_setneighbor(v::GreinerVertex, n::Int) = v.neighbour = n
_setprev(v::GreinerVertex, p::Int) = v.prev = p
_setnext(v::GreinerVertex, n::Int) = v.next = n
_setcoords(v::GreinerVertex, c::Point) = v.coords = c
_setenex(v::GreinerVertex, e::EntryExit) = v.enex = e

Line(p₁::GreinerVertex, p₂::GreinerVertex) = Line(coords(p₁), coords(p₂))
vertices(ring::Vector{GreinerVertex}) = [coords(v) for v in ring]



#inserts p₁ after current
function _insertVertex!(p₁::GreinerVertex, current::GreinerVertex, vertex_vector::Vector{GreinerVertex})
  verticesₜ = vertices(vertex_vector)
  idx = current.next
  p₁.prev = idx - 1
  p₁.next = idx + 1
  # insert p₁ at idx
  insert!(vertex_vector, idx, p₁)
  # update vertex_vector, any vertex next should point one index ahead
  for i in (idx+1):length(vertex_vector)
    vertex_vector[i].next += 1
    vertex_vector[i].prev += 1

  end
end


function _link(v₁::GreinerVertex, v₂::GreinerVertex, verticesS::Vector{GreinerVertex}, verticesC::Vector{GreinerVertex})
  v₁.neighbour = findfirst(x -> x == coords(v₂), vertices(verticesC))
  v₂.neighbour = findfirst(x -> x == coords(v₁), vertices(verticesS))
  v₁.intersection = true
  v₂.intersection = true
end

function _newVertex!(ring::Vector{GreinerVertex}, coords::Point, source=false)
  vertex = GreinerVertex()
  vertex.coords = coords
  vertex.source = source
  if isempty(ring)
    vertex.prev = 1
    vertex.next = 1
    push!(ring, vertex)
  else
    # add vertex at the end
    vertex.prev = length(ring)
    vertex.next = 1
    ring[end].next = length(ring) + 1
    ring[1].prev = length(ring) + 1
    push!(ring, vertex)
  end
end

function _removeVertex(ring::Vector{GreinerVertex}, index::Int)
  if length(ring) == 1
    return Vector{GreinerVertex}()
  end

  prev_index = ring[index].prev
  next_index = ring[index].next

  ring[prev_index].next = next_index
  ring[next_index].prev = prev_index

  deleteat!(ring, index)
  return ring
end

function pointInPoly(R::Point, poly::Ring)
  w = 0
  for i in 1:length(poly)
    P0 = coords(poly[i])
    P1 = coords(poly[mod1(i + 1, length(poly))])

    if (P0.y < R.y) != (P1.y < R.y)
      if P0.x >= R.x
        if P1.x > R.x
          w += 2 * (P1.y > P0.y) - 1
        elseif (_A(P0, P1, R) > 0) == (P1.y > P0.y)
          w += 2 * (P1.y > P0.y) - 1
        end
      elseif P1.x > R.x
        if (_A(P0, P1, R) > 0) == (P1.y > P0.y)
          w += 2 * (P1.y > P0.y) - 1
        end
      end
    end
  end
  return (w % 2) != 0
end

function _allOnOn(ring::Ring)
  for i in 1:length(ring)
    if ring[i].label != IntersectionLabel(5)
      return false
    end
  end
  return true
end

function noCrossingVertex(vertices::Vector{GreinerVertex}, union_case=false)
  for V in vertices
    if V.intersection
      if V.label == IntersectionLabel(1) || V.label == IntersectionLabel(8)
        return false
      end
      if union_case && (V.label == IntersectionLabel(2) || V.label == IntersectionLabel(9))
        return false
      end
    end
  end
  return true
end

function _toggle(point::GreinerVertex)
  if _getenex(point) == EntryExit(2)
    return EntryExit(2)
  end
  point.enex = _getenex(point) == EntryExit(1) ? EntryExit(0) : EntryExit(1)
end

struct VertexPointerDistance
  coords::Point
  distance::Float64
end


#test coords
## shapes that test greiner hormann
ring = Ring((0, 0), (6, 0), (0, 10), (4, 7), (2, 7), (6, 10))
other = Ring((1, 2), (5, 2), (1, 10), (3, 8), (3, 10), (5, 10))

function clip(poly::Polygon, other::Geometry, method::GreinerHormannClipping)
  c = [clip(ring, boundary(other), method) for ring in rings(poly)]
  r = [r for r in c if !isnothing(r)]
  isempty(r) ? nothing : PolyArea(r)
end

function clip(ring::Ring, other::Ring, ::GreinerHormannClipping)
  # make sure other ring is CCW
  γ = orientation(other) == CCW ? other : reverse(other)
  # convert to greiner vertex
  Si = GreinerVertex(ring)
  Cj = GreinerVertex(other)
  # detect intersection points
  Siₜ, Cjₜ, links = computeintersections(Si, Cj)
  # mark entry and exit points
  label1, label2 = markentryexit(Siₜ, Cjₜ)
  # extract union
  disjoint = extractunion(Siₜ, Cjₜ, label1, label2)

  # return polygons for each disjoint
  polygons = [PolyArea(d) for d in disjoint]
  # return multipolygon for each disjoint

  Multi(polygons)
end

function computeintersections(Si, Cj)
  intersection_point_count = 0

  Siₜ = Vector{eltype(Si)}()
  Cjₜ = deepcopy(Cj)

  for i in 1:length(Si)

    vertices_poly1 = Vector{VertexPointerDistance}()

    p₁ = Si[i]
    push!(Siₜ, p₁)
    p₂ = Si[i+1]

    loop2_count = 1
    loop2_total = length(Cjₜ) + 1

    while loop2_count ≤ loop2_total
      α = -1.0
      β = -1.0
      q₁ = Cjₜ[loop2_count]
      q₂ = Cjₜ[loop2_count+1]

      # intersectiontype, α, β = lineintersection(p₁, p₂, q₁, q₂, α, β)
      iₜ = intersection(Line(p₁, p₂), Line(q₁, q₂)) do I
        intersectiontype = I.type
        intersectiongeom = I.geom
        if intersectiontype == Crossing
          return I.geom
        elseif intersectiontype == Overlapping
          return I.geom
        else
          return nothing
        end
      end

      if !isnothing(iₜ)
        intersection_point_count += 1
        # update data
        # write large switch statement to determine intersection type and how to link
        # handle crossing
        if typeof(iₜ) == Point
          # create new vertex
          vᵢ = GreinerVertex(iₜ)
          vⱼ = deepcopy(vᵢ)

          _insertVertex!(vᵢ, p₁, Si)
          _insertVertex!(vⱼ, q₁, Cj)
          _link(vᵢ, vⱼ, Si, Cj)

        end
        loop2_count += 1
      end
      #sort objects waiting for insert
      sort!(vertices_poly1, by=x -> x.distance)
      for item in vertices_poly1
        push!(Siₜ, item.coords)
      end
    end
    if intersection_point_count % 2 != 0
      error("Intersection points must be even")
    end
    return Siₜ, Cjₜ, links
  end
end

function labelintersections(Si, Cj, links)
  # for Polygon 1
  labels₁ = Vector{IntersectionLabel}()
  i = 1
  Sn = length(Si)
  for i in 1:Sn
    p = Si[i]
    ω = winding(p, Ring(Cj))
    # check if vertex of point is on an intersection
    vertex_check = haskey(links, p)

    if vertex_check
      # determine local configuration
      Pₘ = i == 1 ? Si[end] : Si[i-1]
      Pₚ = i == length(Si) ? Si[1] : Si[i+1]

      ## find index of intersection point in Cj
      j = findfirst(isapprox.(p, Cj, atol=1e-10))
      Qₘ = j == 1 ? Cj[end] : Cj[j-1]
      Qₚ = j == length(Cj) ? Cj[1] : Cj[j+1]

      links₁ = [links[[Pₘ]], links[Pₚ]]

      Qₘtype = _oracle(Qₘ, Pₘ, P, Pₚ, links₁)
      Qₚtype = _oracle(Qₚ, Pₘ, P, Pₚ, links₁)

      #non overlaps

      if ((Qₘtype == RelativePositionType(0) && Qₚtype == RelativePositionType(1)) ||
          (Qₘtype == RelativePositionType(1) && Qₚtype == RelativePositionType(0)))
        push!(labels₁, EntryExit(1))
      end
      if ((Qₘtype == RelativePositionType(0) && Qₚtype == RelativePositionType(0)) ||
          (Qₘtype == RelativePositionType(1) && Qₚtype == RelativePositionType(1)))
        push!(labels₁, EntryExit(2))
      end

      #overlaps
      if ((Qₚtype == RelativePositionType(3) && Qₘtype == RelativePositionType(1)) ||
          (Qₘtype == RelativePositionType(2) && Qₚtype == RelativePositionType(1)))
        push!(labels₁, EntryExit(3))
      end
      if ((Qₚtype == RelativePositionType(3) && Qₘtype == RelativePositionType(0)) ||
          (Qₘtype == RelativePositionType(2) && Qₚtype == RelativePositionType(0)))
        push!(labels₁, EntryExit(4))
      end
      if ((Qₚtype == RelativePositionType(3) && Qₘtype == RelativePositionType(2))) ||
         ((Qₘtype == RelativePositionType(3) && Qₚtype == RelativePositionType(2)))
        push!(labels₁, IntersectionLabel(5))
      end

      if ((Qₘtype == RelativePositionType(2) && Qₚtype == RelativePositionType(1))) ||
         ((Qₚtype == RelativePositionType(2) && Qₘtype == RelativePositionType(1)))
        push!(labels₁, IntersectionLabel(6))
      end

      if ((Qₘtype == RelativePositionType(2) && Qₚtype == RelativePositionType(0))) ||
         ((Qₚtype == RelativePositionType(2) && Qₘtype == RelativePositionType(0)))
        push!(labels₁, IntersectionLabel(7))
      end

      if labels₁[end] == IntersectionLabel(3) || labels₁[end] == IntersectionLabel(4)
        x = RelativePositionType(0)
        y = RelativePositionType(0)
        if labels₁[end] == IntersectionLabel(3)
          x = RelativePositionType(0)
        else
          x = RelativePositionType(1)
        end
        # proceed to end of intersection chain and mark all visited vertices as NONE
        while label₁[end] == IntersectionLabel(5)
          label₁[end] = IntersectionLabel(0)
        end

        if label₁ == IntersectionLabel(6)
          y = RelativePositionType(0)
        else
          y = RelativePositionType(1)
        end

        # determine type of intersection chain
        if x != y
          chainType = IntersectionLabel(8)
          count[1] += 1
        else
          chainType = IntersectionLabel(9)
          count[2] += 1
        end

        # mark both ends of an intersection chain with chainType (i.e., as DELAYED_*)
        X.label = chainType
        I.label = chainType
      end

      # classify intersection chains

      # 3) copy labels from P to Q
      for P in PP
        for I in vertices(P, IntersectionType.X)
          I.neighbour.label = I.label
        end
      end

      # 3.5) check for special cases
      noIntersection = Vector{Set{Polygon}}(undef, 2)
      identical = Vector{Set{Polygon}}(undef, 2)
      noIntersection[1] = Set{Polygon}()
      noIntersection[2] = Set{Polygon}()
      identical[1] = Set{Polygon}()
      identical[2] = Set{Polygon}()

      count = [0, 0]

      for i in 1:2
        P_or_Q = i == 1 ? PP : QQ
        Q_or_P = i == 1 ? QQ : PP

        for P in P_or_Q
          if noCrossingVertex(P, IntersectionType.X)
            push!(noIntersection[i], P)
            if allOnOn(P)
              push!(identical[i], P)
            else
              isInside = false
              p = getNonIntersectionPoint(P)
              for Q in Q_or_P
                if pointInPoly(Q, p)
                  isInside = !isInside
                end
              end
              if isInside != UNION
                push!(RR, P)
                count[1] += 1
              end
            end
          end
        end
      end

      for P in identical[1]
        P_isHole = false
        for P_ in PP
          if P_.root != P.root && pointInPoly(P_, P.root.p)
            P_isHole = !P_isHole
          end
        end

        for Q in identical[2]
          for V in vertices(Q, IntersectionType.all)
            if V == P.root.neighbour
              Q_isHole = false
              for Q_ in QQ
                if Q_.root != Q.root && pointInPoly(Q_, Q.root.p)
                  Q_isHole = !Q_isHole
                end
              end

              if P_isHole == Q_isHole
                push!(RR, P)
                count[2] += 1
              end
              break
            end
          end
        end
      end

      println("... ", count[1], " interior and ", count[2], " identical components added to result")

      # 4) set entry/exit flags
      split = Vector{Set{Vertex}}(undef, 2)
      crossing = Vector{Set{Vertex}}(undef, 2)
      split[1] = Set{Vertex}()
      split[2] = Set{Vertex}()
      crossing[1] = Set{Vertex}()
      crossing[2] = Set{Vertex}()

      for i in 1:2
        P_or_Q = i == 1 ? PP : QQ
        Q_or_P = i == 1 ? QQ : PP

        for P in P_or_Q
          if P in noIntersection[i]
            continue
          end

          V = getNonIntersectionVertex(P)
          status = EntryExit.entry
          for Q in Q_or_P
            if pointInPoly(Q, V.p)
              status = toggle(status)
            end
          end

          first_chain_vertex = true
          for I in vertices(P, IntersectionType.X, V)
            if I.label == IntersectionLabel.crossing
              I.enex = status
              status = toggle(status)
            end

            if I.label == IntersectionLabel.bouncing && (status == EntryExit.exit) != UNION
              push!(split[i], I)
            end

            if I.label == IntersectionLabel.delayed_crossing
              I.enex = status
              if first_chain_vertex
                if (status == EntryExit.exit) != UNION
                  I.label = IntersectionLabel.crossing
                end
                first_chain_vertex = false
              else
                if (status == EntryExit.entry) != UNION
                  I.label = IntersectionLabel.crossing
                end
                first_chain_vertex = true
                status = toggle(status)
              end
            end

            if I.label == IntersectionLabel.delayed_bouncing
              I.enex = status
              if first_chain_vertex
                if (status == EntryExit.exit) != UNION
                  push!(crossing[i], I)
                end
                first_chain_vertex = false
              else
                if (status == EntryExit.entry) != UNION
                  push!(crossing[i], I)
                end
                first_chain_vertex = true
              end
              status = toggle(status)
            end
          end
        end
      end

      # 5) handle split vertex pairs
      count[1] = 0

      for I_P in split[1]
        I_Q = I_P.neighbour
        if I_Q in split[2]
          count[1] += 1

          V_P = Vertex(I_P.p)
          V_Q = Vertex(I_Q.p)

          sP = _A(I_P.prev.p, I_P.p, I_P.next.p)
          sQ = _A(I_Q.prev.p, I_Q.p, I_Q.next.p)

          if sP * sQ > 0
            link(I_P, V_Q)
            link(I_Q, V_P)
          else
            link(V_P, V_Q)
          end

          _insertVertex!(V_P, I_P)
          _insertVertex!(V_Q, I_Q)

          if !UNION
            I_P.enex = EntryExit.exit
            V_P.enex = EntryExit.entry
            I_Q.enex = EntryExit.exit
            V_Q.enex = EntryExit.entry
          else
            I_P.enex = EntryExit.entry
            V_P.enex = EntryExit.exit
            I_Q.enex = EntryExit.entry
            V_Q.enex = EntryExit.exit
          end

          I_P.label = IntersectionLabel.crossing
          V_P.label = IntersectionLabel.crossing
          I_Q.label = IntersectionLabel.crossing
          V_Q.label = IntersectionLabel.crossing
        end
      end

      println("... ", count[1], " bouncing vertex pairs split")

      # 6) handle CROSSING vertex candidates
      for I_P in crossing[1]
        I_Q = I_P.neighbour
        if I_Q in crossing[2]
          I_P.label = IntersectionLabel.crossing
          I_Q.label = IntersectionLabel.crossing
        end
      end



    end
  end






  return labels₁, labels₂
end

function extractunion(Si, Cj, label1, label2)
  # now create multiple rings for disjoint polygons by tracing

  # build neighborhood lists to allow switching between Si and Cj for tracing
  # if label is 2 | 3 then switch dataset to the same vertex
  Si_neighborhood = Dict{Int,Int}()
  Cj_neighborhood = Dict{Int,Int}()
  for i in 1:length(Si)
    pₜ = Si[i]
    if label1[i] == EntryExit(2) || label1[i] == EntryExit(3)
      # point towards same vertex in Cj
      ptr = findfirst(isapprox.(pₜ, Cj, rtol=0.001))
      #dictionary to store index of vertex and ptr
      push!(Si_neighborhood, i => ptr)
    end
  end
  for i in 1:length(Cj)
    pₜ = Cj[i]
    if label2[i] == EntryExit(2) || label2[i] == EntryExit(3)
      # point towards same vertex in Si
      ptr = findfirst(isapprox.(pₜ, Si, rtol=0.001))
      # dictionary to store index of vertex and ptr
      push!(Cj_neighborhood, i => ptr)
    end
  end




  disjoint = Vector{Ring}()
  ring = Vector{eltype(Si)}()
  polygon_numbs = [1, 2]
  active_polygon = polygon_numbs[1]

  for i in 1:length(Si)
    pₛ = Si[i]
    #check if outside, or if already in disjoint
    if !isempty(disjoint)
      latest_disjoint = vertices(disjoint[end])
      if any(isapprox.(pₛ, latest_disjoint, rtol=0.001))
        continue
      end
    end
    if label1[i] == EntryExit(1)
      continue
    end
    push!(ring, pₛ)
    j = deepcopy(i) + 1
    if i == length(Si)
      j = 1
    end
    pᵢ = Si[j]
    loops = 0
    while loops < 20 && !isapprox(pᵢ, pₛ, rtol=0.001)
      push!(ring, pᵢ)
      loops += 1
      @show pₛ, pᵢ, j
      if active_polygon == 1
        # check if exit, then switch to Cj if so
        if label1[j] == EntryExit(3)
          # switch to Cj
          active_polygon = 2
          j = Si_neighborhood[j] + 1

          j = j > length(Si) ? 1 : j

          pᵢ = Cj[j]
        else
          # continue in Si
          j += 1
          j = j > length(Si) ? 1 : j

          pᵢ = Si[j]
        end
      else
        # check if pᵢ is in Si_neighborhood
        if label2[j] == EntryExit(3)
          # switch to Si
          active_polygon = 1
          j = Cj_neighborhood[j] + 1

          j = j == length(Si) ? 1 : j

          pᵢ = Si[j]
        else
          # continue in Cj
          j += 1
          j = j > length(Si) ? 1 : j

          pᵢ = Cj[j]
        end
      end
    end
    push!(disjoint, Ring(ring))
  end


  return disjoint
end



# p₁ = Point((0, 1))
# p₂ = Point((2, 1))
# q₁ = Point((1, 0))
# q₂ = Point((1, 2))

function lineintersection(p₁::Point, p₂::Point, q₁::Point, q₂::Point, α, β)
  AP₁ = ustrip(_A(p₁, q₁, q₂))
  AP₂ = ustrip(_A(p₂, q₁, q₂))

  abs(AP₁ - AP₂)
  if abs(AP₁ - AP₂) > 1e-10
    # no parallel
    AQ₁ = ustrip(_A(q₁, p₁, p₂))
    AQ₂ = ustrip(_A(q₂, p₁, p₂))

    α = AQ₁ / (AQ₁ - AQ₂)
    β = AP₁ / (AP₁ - AP₂)

    # classify α
    α_is_0 = false
    α_is_0_1 = false
    if α > 1e-10 && α < 1.0 - 1e-10
      α_is_0 = true
    elseif abs(α) < 1e-10
      α_is_0_1 = true
    end

    # classify β
    β_is_0 = false
    β_is_0_1 = false
    if β > 1e-10 && β < 1.0 - 1e-10
      β_is_0 = true
    elseif abs(β) < 1e-10
      β_is_0_1 = true
    end

    # distinguish intersection types
    if α_is_0_1 && β_is_0_1
      return IntersectionType(0), α, β
    elseif α_is_0 && β_is_0_1
      return IntersectionType(1), α, β
    elseif α_is_0_1 && β_is_0
      return IntersectionType(4), α, β
    elseif α_is_0 && β_is_0
      return IntersectionType(3), α, β
    end
  else
    if (abs(AP₁) < 1e-10)
      # handling collinear
      dP = p₂ - p₁
      dQ = q₂ - q₁
      PQ = q₁ - p₁

      # compute alpha and beta
      α = (PQ ⋅ dP) / (dP ⋅ dP)
      β = (PQ ⋅ dQ) / (dQ ⋅ dQ)

      # classify α
      α_is_0 = false
      α_in_0_1 = false
      α_not_in_0_1 = false

      if (α > 1e-10) && (α < 1.0 - 1e-10)
        α_in_0_1 = true
      elseif abs(α) <= 1e-10
        α_is_0 = true
      else
        α_not_in_0_1 = true
      end

      β_is_0 = false
      β_in_0_1 = false
      β_not_in_0_1 = false

      if (β > 1e-10) && (β < 1.0 - 1e-10)
        β_in_0_1 = true
      elseif abs(β) <= 1e-10
        β_is_0 = true
      else
        β_not_in_0_1 = true
      end

      if α_in_0_1 && β_in_0_1
        return IntersectionType(6), α, β
      elseif α_not_in_0_1 && β_in_0_1
        return IntersectionType(7), α, β
      elseif β_not_in_0_1 && α_in_0_1
        return IntersectionType(8), α, β
      elseif α_is_0 && β_is_0
        return IntersectionType(8), α, β
      end
    end
  end
  return IntersectionType(9), α, β
end

function lineintersection(v₁::GreinerVertex, v₂::GreinerVertex, v₃::GreinerVertex, v₄::GreinerVertex, α, β)
  p₁ = coords(v₁)
  p₂ = coords(v₂)
  q₁ = coords(v₃)
  q₂ = coords(v₄)
  lineintersection(p₁, p₂, q₁, q₂, α, β)
end

_calc_WEC(v₁, v₂) = ustrip(sum([a * b for (a, b) in zip(v₁, v₂)]))
_calc_α(weq₁, weq₂) = weq₁ / (weq₁ - weq₂)
_perturb_point(p₁, p₂, perturbation) = (p₁ - p₂) * perturbation + p₂

_create_vertex(p₁, p₂, α) = α * (p₂ - p₁) + p₁


function _A(P::T, Q::T, R::T) where {T<:Point}
  (coords(Q).x - coords(P).x) * (coords(R).y - coords(P).y) - (coords(Q).y - coords(P).y) * (coords(R).x - coords(P).x)
end

function _oracle(Q, p₁, p₂, p₃, intersectiontypes)
  if intersectiontypes[1] && p₁ == Q
    return RelativePositionType(2)
  end
  if intersectiontypes[2] && p₃ == Q
    return RelativePositionType(3)
  end

  s₁ = _A(Q, p₁, p₂)
  s₂ = _A(Q, p₂, p₃)
  s₃ = _A(p₁, p₂, p₃)

  if s3 > 0
    if s₁ > 0 && s₂ > 0
      return RelativePositionType(0)
    else
      return RelativePositionType(1)
    end
  else
    if s₁ < 0 && s₂ < 0
      return RelativePositionType(1)
    else
      return RelativePositionType(0)
    end
  end
end
