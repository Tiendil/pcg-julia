module Spaces

using ..PCG.Geometry: Point, BoundingBox, Size
using ..PCG.Types: Recorder, Recorders, NodeProperties

export Space, Node, Nodes, record_state, turn, space_size, check, register!, apply_changes

mutable struct Node{P<:NodeProperties}
    index::Int64 # TODO: rename to space_index ?
    coordinates::Point # TODO: rename to topology_index ?
    updated::Bool
    properties::P
end

Node(properties::P) where P = Node(0, Point(0, 0), false, properties)

const Nodes = Array{<:Node, 1}

# TODO: is it right?
Base.zero(::Type{Node}) = Node(nothing)


# TODO: replace with template copy method?
function Base.deepcopy(node::Node)
    return Node(node.index,
                node.coordinates,
                false,
                deepcopy(node.properties))
end


mutable struct Space{NODE <: Node}
    _base_nodes::Array{NODE, 1}
    _new_nodes::Array{Union{Nothing, NODE}}
    _recorders::Recorders
end

Space{NODE}(recorders::Recorders) where NODE <: Node = Space{NODE}([], [], recorders)
Space{NODE}() where NODE <: Node = Space{NODE}([], [], Array{Recorder, 1}())


function register!(space::Space, node::Node)
    node.index = length(space._base_nodes) + 1

    # TODO: reserve memory for _base_nodes and _new_node
    push!(space._base_nodes, node)
    push!(space._new_nodes, nothing)
end


Base.length(space::Space{Node}) = length(space._base_nodes)


function record_state(space::Space)
    for recorder in space._recorders
        record_state(space, recorder)
    end
end


function apply_changes(space::Space)

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


function space_size(nodes::Nodes)

    # TODO: rewrite to redefiend function?
    if isempty(nodes)
        return Size(BoundingBox())
    end

    coordinates = [node.coordinates for node in nodes]

    return Size(BoundingBox(coordinates))
end


function check
end


end
