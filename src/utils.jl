# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

# auxiliary type for dispatch purposes
const GeometryOrDomain = Union{Geometry,Domain}

include("utils/basic.jl")
include("utils/assert.jl")
include("utils/cmp.jl")
include("utils/units.jl")
include("utils/crs.jl")
include("utils/misc.jl")
include("utils/sweepline.jl")
