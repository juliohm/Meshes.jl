# Implementation of Bentley-Ottmann algorith
# https://en.wikipedia.org/wiki/Bentley%E2%80%93Ottmann_algorithm

using BinaryTrees

"""
    bentleyottmann(segments)

Compute pairwise intersections between n `segments`
in O(n⋅log(n)) time using Bentley-Ottmann sweep line
algorithm.
"""
function bentleyottmann(segments)
  # adjust vertices of segments
  segs = map(segments) do s
    a, b = extrema(s)
    a > b ? reverse(s) : s
  end

  # retrieve relevant info
  s = first(segs)
  p = minimum(s)
  P = typeof(p)
  S = Tuple{P,P}

  # initialization
  𝒬 = BinaryTrees.AVLTree{P}()
  𝒯 = BinaryTrees.AVLTree{S}()
  ℒ = Dict{P,Vector{S}}()
  𝒰 = Dict{P,Vector{S}}()
  𝒞 = Dict{P,Vector{S}}()
  for s in segs
    a, b = extrema(s)
    BinaryTrees.insert!(𝒬, a)
    BinaryTrees.insert!(𝒬, b)
    haskey(ℒ, a) ? push!(ℒ[a], (a, b)) : (ℒ[a] = [(a, b)])
    haskey(𝒰, b) ? push!(𝒰[b], (a, b)) : (𝒰[b] = [(a, b)])
    haskey(ℒ, b) || (ℒ[b] = S[])
    haskey(𝒰, a) || (𝒰[a] = S[])
    haskey(𝒞, a) || (𝒞[a] = S[])
    haskey(𝒞, b) || (𝒞[b] = S[])
  end

  # sweep line
  I = Dict{P,Vector{S}}()
  while !isnothing(BinaryTrees.root(𝒬))
    p = _key(_leftmost(BinaryTrees.root(𝒬)))
    BinaryTrees.delete!(𝒬, p)
    handle!(I, p, 𝒬, 𝒯, ℒ, 𝒰, 𝒞)
  end
  I
end

function handle!(I, p, 𝒬, 𝒯, ℒ, 𝒰, 𝒞)
  start_segments = get(ℒ, p, S[])
  end_segments = get(𝒰, p, S[])
  intersection_segments = get(𝒞, p, S[])
  _process_start_segments!(start_segments, 𝒬, 𝒯, 𝒞)
  _process_end_segments!(end_segments, 𝒬, 𝒯, 𝒞)
  _process_intersection_segments!(intersection_segments, 𝒬, 𝒯, 𝒞)

  if length(start_segments ∪ end_segments ∪ intersection_segments) > 1
    I[p] = start_segments ∪ end_segments ∪ intersection_segments
  end
end

function _process_start_segments!(start_segments, 𝒬, 𝒯, 𝒞)
  [BinaryTrees.insert!(𝒯, s) for s in start_segments]
  for s in start_segments
    above, below = find_above_below(BinaryTrees.root(𝒯), BinaryTrees.search(𝒯, s))
    s = Segment(s)
    if above !== nothing && below !== nothing
      new_geom, new_type = _newevent(Segment(_key(above)), Segment(_key(below)))
      if new_type == IntersectionType(0)
        BinaryTrees.insert!(𝒬, new_geom)
        haskey(𝒞, new_geom) ? push!(𝒞[new_geom], _key(above), _key(below)) : (𝒞[new_geom] = [_key(above), _key(below)])
      end
    end
    if below !== nothing
      new_geom, new_type = _newevent(Segment(_key(below)), s)
      if new_type == IntersectionType(0)
        BinaryTrees.insert!(𝒬, new_geom)
        haskey(𝒞, new_geom) ? push!(𝒞[new_geom], _key(below), _segdata(s)) : (𝒞[new_geom] = [_key(below), _segdata(s)])
      end
    end
    if above !== nothing
      new_geom, new_type = _newevent(s, Segment(_key(above)))
      if new_type == IntersectionType(0)
        BinaryTrees.insert!(𝒬, new_geom)
        haskey(𝒞, new_geom) ? push!(𝒞[new_geom], _segdata(s), _key(above)) : (𝒞[new_geom] = [_segdata(s), _key(above)])
      end
    end
  end
end

function _process_end_segments!(end_segments, 𝒬, 𝒯, 𝒞)
  for s in end_segments
    above, below = find_above_below(BinaryTrees.root(𝒯), BinaryTrees.search(𝒯, s))
    BinaryTrees.delete!(𝒯, s)
    s = Segment(s)
    if above !== nothing && below !== nothing
      new_geom, new_type = _newevent(Segment(_key(above)), Segment(_key(below)))
      if new_type == IntersectionType(0)
        BinaryTrees.insert!(𝒬, new_geom)
        haskey(𝒞, new_geom) ? push!(𝒞[new_geom], _key(above), _key(below)) : (𝒞[new_geom] = [_key(above), _key(below)])
      end
    end
  end
end

function _process_intersection_segments!(intersection_segments, 𝒬, 𝒯, 𝒞)
  for s in intersection_segments
    _, below = find_above_below(BinaryTrees.root(𝒯), BinaryTrees.search(𝒯, s))
    if below !== nothing
      # Swap positions of s and t in 𝒯
      BinaryTrees.delete!(𝒯, s)
      BinaryTrees.delete!(𝒯, _key(below))
      BinaryTrees.insert!(𝒯, _key(below))
      BinaryTrees.insert!(𝒯, s)

      # Find segments r and u
      _, r = find_above_below(BinaryTrees.root(𝒯), BinaryTrees.search(𝒯, _key(below)))
      u, _ = find_above_below(BinaryTrees.root(𝒯), BinaryTrees.search(𝒯, s))

      # Remove crossing points rs and tu from event queue
      if r !== nothing
        new_geom, new_type = _newevent(Segment(_key(r)), Segment(s))
        if new_type == IntersectionType(0)
          BinaryTrees.delete!(𝒬, new_geom)
        end
      end
      if u !== nothing
        new_geom, new_type = _newevent(Segment(_key(u)), Segment(_key(below)))
        if new_type == IntersectionType(0)
          BinaryTrees.delete!(𝒬, new_geom)
        end
      end

      # Add crossing points rt and su to event queue
      if r !== nothing
        new_geom, new_type = _newevent(Segment(_key(r)), Segment(_key(below)))
        if new_type == IntersectionType(0)
          BinaryTrees.insert!(𝒬, new_geom)
          haskey(𝒞, new_geom) ? push!(𝒞[new_geom], _key(r), _key(below)) : (𝒞[new_geom] = [_key(r), _key(below)])
        end
      end
      if u !== nothing
        new_geom, new_type = _newevent(Segment(_key(u)), Segment(s))
        if new_type == IntersectionType(0)
          BinaryTrees.insert!(𝒬, new_geom)
          haskey(𝒞, new_geom) ? push!(𝒞[new_geom], _key(u), s) : (𝒞[new_geom] = [_key(u), s])
        end
      end
    end
  end
end

_segdata(seg::Segment) = seg.vertices.data
_key(node::BinaryTrees.AVLNode) = node.key
_key(node::Nothing) = nothing
_leftmost(node::BinaryTrees.AVLNode) = node.left === nothing ? node : _leftmost(node.left)
_geom(intersect::Intersection) = intersect.geom
_type(intersect::Intersection) = intersect.type
function _newevent(s₁::Segment, s₂::Segment)
  new_event = intersection(s₁, s₂)
  if new_event !== nothing
    _geom(new_event), _type(new_event)
  else
    nothing, nothing
  end
end

# Helper: return the leftmost node (minimum) in a subtree.
function _bst_minimum(node::BinaryTrees.AVLNode)
  while node.left !== nothing
    node = node.left
  end
  return node
end

# Helper: return the rightmost node (maximum) in a subtree.
function _bst_maximum(node::BinaryTrees.AVLNode)
  while node.right !== nothing
    node = node.right
  end
  return node
end

"""
    find_above_below(root, x)

Find the node above and below `x` in the binary search tree rooted at `root`.
Returns a tuple `(above, below)` where `above` is the node with the smallest key
greater than `x.key` and `below` is the node with the largest key smaller than `x.key`.
If `x` is not found, returns the best candidates for `above` and `below`.
"""
function find_above_below(root::BinaryTrees.AVLNode, x::BinaryTrees.AVLNode)
  above = nothing
  below = nothing
  current = root
  # Traverse from the root to the target node, updating candidates.
  while current !== nothing && current.key != x.key
    if x.key < current.key
      # current is a potential above (successor)
      above = current
      current = current.left
    else # x.key > current.key
      # current is a potential below (predecessor)
      below = current
      current = current.right
    end
  end

  # If the node wasn't found, return the best candidate values
  if current === nothing
    return (above, below)
  end

  # Found the node with key equal to x.key.
  # Now, if there is a left subtree, the true below (predecessor) is the maximum in that subtree.
  if current.left !== nothing
    below = _bst_maximum(current.left)
  end
  # Similarly, if there is a right subtree, the true above (successor) is the minimum in that subtree.
  if current.right !== nothing
    above = _bst_minimum(current.right)
  end

  (above, below)
end
find_above_below(root::BinaryTrees.AVLNode, x::Nothing) = (nothing, nothing)
function Segment(node₁::BinaryTrees.BinaryNode, node₂::BinaryTrees.BinaryNode)
  node₁ = _key(node₁)
  node₂ = _key(node₂)
  Segment((node₁, node₂))
end
