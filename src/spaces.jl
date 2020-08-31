module Spaces

using ..PCG.Geometry: Point, BoundingBox, Size
using ..PCG.Types: Recorder, Recorders

export Space, Node, record_state, turn, space_size, check, register!, apply_changes

mutable struct Space{NODE}
    _base_nodes::Array{NODE}
    _new_nodes::Array{Union{Nothing, NODE}}
    _recorders::Recorders
end

Space{NODE}(recorders::Recorders) where NODE = Space{NODE}([], [], recorders)

mutable struct Node
    index::Int64 # TODO: rename to space_index ?
    coordinates::Point # TODO: rename to topology_index ?
    _new_node::Union{Nothing, Node}
    space::Union{Nothing, Space}

    # TODO: replace Any with template parameter declaration
    properties::Any

    Node(properties::Any) = new(0, Point(0, 0), nothing, nothing, properties)

    function Node(index::Int64, coordinates::Point, _new_node::Union{Nothing, Node}, space::Union{Nothing, Space}, properties::Any)
        return new(index, coordinates, _new_node, space, properties)
    end
end

Node() = Node(nothing)

# TODO: is it right?
Base.zero(::Type{Node}) = Node(nothing)


# TODO: replace with template copy method?
function Base.deepcopy(node::Node)
    return Node(node.index,
                node.coordinates,
                deepcopy(node._new_node),
                node.space,
                deepcopy(node.properties))
end


function register!(space::Space{Node}, node::Node)
    node.space = space
    node.index = length(space._base_nodes) + 1

    # TODO: reserve memory for _base_nodes and _new_node
    push!(space._base_nodes, node)
    push!(space._new_nodes, nothing)
end


Base.length(space::Space{Node}) = length(space._base_nodes)


function record_state(space::Space{Node})
    for recorder in space._recorders
        record_state(space, recorder)
    end
end


function apply_changes(space::Space{Node})

    # TODO: rewrite from coping single nodes to memory regions switching

    for (i, node) in enumerate(space._new_nodes)
        if isnothing(node)
            continue
        end

        space._base_nodes[i] = node
        space._new_nodes[i] = nothing
    end

    record_state(space)
end


function space_size(nodes::Array{Node, 1})

    # TODO: rewrite to redefiend function?
    if isempty(nodes)
        return BoundingBox()
    end

    coordinates = [node.coordinates for node in nodes]

    return Size(BoundingBox(coordinates))
end


function check
end


end
