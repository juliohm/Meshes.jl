# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    intersecttype(f, segment, triangle)

Calculate the intersection type of `segment and `triangle`
and apply function `f` to it.

## References

* Jiménez, J., Segura, R. and Feito, F. 2009. [A robust segment/triangle
  intersection algorithm for interference tests. Efficiency study]
  (https://www.sciencedirect.com/science/article/pii/S0925772109001448?via%3Dihub)
"""
function intersecttype(f::Function, s::Segment{3,T}, t::Triangle{3,T}) where {T}
  vₛ = vertices(s)
  vₜ = vertices(t)

  A = vₛ[1] - vₜ[3]
  B = vₜ[1] - vₜ[3]
  C = vₜ[2] - vₜ[3]

  W₁ = B × C
  wᵥ = A ⋅ W₁

  D = vₛ[2] - vₜ[3]
  sᵥ = D ⋅ W₁

  if wᵥ > atol(T)
    # rejection 2
    if sᵥ > atol(T)
      return NoIntersection() |> f
    end

    W₂ = A × D
    tᵥ = W₂ ⋅ C

    # rejection 3
    if tᵥ < -atol(T)
      return NoIntersection() |> f
    end

    uᵥ = -(W₂ ⋅ B)

    # rejection 4
    if uᵥ < -atol(T)
      return NoIntersection() |> f
    end

    # rejection 5
    if wᵥ < (sᵥ + tᵥ + uᵥ)
      return NoIntersection() |> f
    end
  elseif wᵥ < -atol(T)
    # rejection 2
    if sᵥ < -atol(T)
      return NoIntersection() |> f
    end

    W₂ = A × D
    tᵥ = W₂ ⋅ C

    # rejection 3
    if tᵥ > atol(T)
      return NoIntersection() |> f
    end

    uᵥ = -(W₂ ⋅ B)

    # rejection 4
    if uᵥ > atol(T)
      return NoIntersection() |> f
    end

    # rejection 5
    if wᵥ > (sᵥ + tᵥ + uᵥ)
      return NoIntersection() |> f
    end
  else
    if sᵥ > atol(T)
      W₂ = D × A
      tᵥ = W₂ ⋅ C

      # rejection 3
      if tᵥ < -atol(T)
        return NoIntersection() |> f
      end

      uᵥ = -(W₂ ⋅ B)

      # rejection 4
      if uᵥ < -atol(T)
        return NoIntersection() |> f
      end
      # rejection 5
      if -sᵥ < (tᵥ + uᵥ)
        return NoIntersection() |> f
      end
    elseif sᵥ < -atol(T)
      W₂ = D × A
      tᵥ = W₂ ⋅ C

      # rejection 3
      if tᵥ > atol(T)
        return NoIntersection() |> f
      end

      uᵥ = -(W₂ ⋅ B)

      # rejection 4
      if uᵥ > atol(T)
        return NoIntersection() |> f
      end

      # rejection 5
      if -sᵥ > (tᵥ + uᵥ)
        return NoIntersection() |> f
      end
    else
      # rejection 1, coplanar segment
      return NoIntersection() |> f
    end
  end

  λ = clamp(wᵥ / (wᵥ - sᵥ), zero(T), one(T))

  return IntersectingSegmentTriangle(s(λ)) |> f
end

"""
    intersecttype(s, t)

Calculate the intersection of a ray and triangle in 3D
and apply function `f` to it.

## References

* Möller, T. and Trumbore, B., 1997. [Fast, minimum storage ray-triangle
  intersection. Journal of graphics tools]
  (https://www.tandfonline.com/doi/abs/10.1080/10867651.1997.10487468)
"""
function intersecttype(f::Function, r::Ray{3,T}, t::Triangle{3,T}) where {T}
  vₜ = vertices(t)
  origin = r.p
  D = r.v

  E₁ = vₜ[3] - vₜ[1]
  E₂ = vₜ[2] - vₜ[1]
  P = D × E₂
  det = E₁ ⋅ P

  # keep det > 0, modify T accordingly
  if det > atol(T)
    TT = origin - vₜ[1]
  else
    TT = vₜ[1] - origin
    det = -det
  end

  if det < atol(T)
      # This ray is parallel to the plane of the triangle.
      return NoIntersection() |> f
  end

  # calculate u parameter and test bounds
  u = TT ⋅ P
  if u < -atol(T) || u > det
      return NoIntersection() |> f
  end

  Q = TT × E₁

  # calculate v parameter and test bounds
  v = D ⋅ Q
  if v < -atol(T) || u + v > det
      return NoIntersection() |> f
  end

  t = E₂ ⋅ Q

  invdet = one(T) / det
  t *= invdet

  if t < -atol(T)
      return NoIntersection() |> f
  end

  return IntersectingRayTriangle(r(t)) |> f
end
