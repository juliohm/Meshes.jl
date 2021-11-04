# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    intersecttype(segment, plane)

Compute the intersection of a segment `s` and a plane `p`
See https://en.wikipedia.org/wiki/Line-plane_intersection
"""
function intersecttype(s::Segment{3,T}, p::Plane{3,T}) where {T}
    # Convert the positions of the segment vertices and the plane origin to coordinates
    sᵥ = coordinates.(vertices(s))
    pₒ = coordinates(origin(p))

    # Get the normal of the plane
    n = normal(p)
    
    # Calculate components
    ln = (sᵥ[2] - sᵥ[1]) ⋅ n
    pₒn = pₒ ⋅ n
  
    # If ln is zero, the segment is parallel to the plane
    if isapprox(ln, zero(T))
        # If the numerator is zero, the segment is coincident
        if isapprox(pₒn, sᵥ[1])
            return ContainedSegmentPlane(s)
        else
            return NoIntersection()
        end
    else
        # Calculate the segment parameter
        λ = ((pₒ - sᵥ[1]) ⋅ n) / ln

        # If λ is approximately 0 or 1, set as so to prevent any domain errors
        λ = isapprox(λ, zero(T), atol=atol(T)) ? zero(T) : (isapprox(λ, one(T), atol=atol(T)) ? one(T) : λ)

        # If λ is out of bounds for the segment, then there is no intersection
        if (λ < zero(T)) || (λ > one(T))
            return NoIntersection()
        else
            return IntersectingSegmentPlane(s(λ))
        end
    end
  end