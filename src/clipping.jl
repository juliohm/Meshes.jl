# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    ClippingMethod

A method for clipping geometries with other geometries.
"""
abstract type ClippingMethod end

"""
    clip(geometry, other, method)

Clip the subject `geometry` with `other` geometry using clipping `method`.
"""
function clip end

# ----------------
# IMPLEMENTATIONS
# ----------------

include("clipping/sutherlandhodgman.jl")
include("clipping/weileratherton.jl")
