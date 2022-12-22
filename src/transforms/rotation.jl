# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
  RotateCoords(rot)

Rotate geometry or mesh with rotation `rot` from ReferenceFrameRotations.jl. 

## Examples

```julia
RotateCoords(EulerAngleAxis(pi/4, [1, 0, 0]))
```
"""
struct RotateCoords{R} <: GeometricTransform
  rot::R
end

isrevertible(::Type{<:RotateCoords}) = true

function preprocess(transform::RotateCoords, object)
  rot = transform.rot
  R, R⁻¹ = inv(rot), rot
  convert.(DCM, (R, R⁻¹))
end

function applypoint(::RotateCoords, points, prep)
  M, _ = prep
  newpoints = [Point(M * coordinates(p)) for p in points]
  newpoints, prep
end

function revertpoint(::RotateCoords, newpoints, cache)
  _, M⁻¹ = cache
  [Point(M⁻¹ * coordinates(p)) for p in newpoints]
end

function reapplypoint(::RotateCoords, points, cache)
  M, _ = cache
  [Point(M * coordinates(p)) for p in points]
end
