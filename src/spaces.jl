module Spaces

using ..PCG.Geometry: Point, BoundingBox, Size
using ..PCG.Topologies: Topology
using ..PCG.Recorders: Recorder

export Space, Node, record_state, turn, space_size, base_nodes, check

mutable struct Space{NODE}
    _base_nodes::Array{NODE}
    _new_nodes::Array{Union{Nothing, NODE}}
    topology::Topology
    _recorders::Array{Recorder}
end

Space{NODE}(topology::Topology, recorders::Array{Recorder}) where NODE = Space{NODE}([], [], topology, recorders)

mutable struct Node
    index::Int32
    coordinates::Point
    _new_node::Union{Nothing, Node}
    space::Union{Nothing, Space}

    # TODO: replace Any with template parameter declaration
    properties::Any

    Node(properties::Any) = new(0, Point(0, 0), nothing, nothing, properties)
    function Node(index::Int32, coordinates::Point, _new_node::Union{Nothing, Node}, space::Union{Nothing, Space}, properties::Any)
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


Base.length(space::Space{Node}) = length(space._base_nodes)


function record_state(space::Space{Node})
    for recorder in space._recorders
        record_state(space, recorder)
    end
end


function turn(callback::Any, space::Space{Node})

    callback(space)

    for (i, node) in enumerate(space._new_nodes)
        if !isnothing(node)
            space._base_nodes[i] = node
            space._new_nodes[i] = nothing
        end
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


# TODO: replace Any with appropriate type
# TODO: does "callback" good solution?
function base_nodes(callback::Any, space::Space{Node}, filter::Any, indexes::Any)
    for i in indexes
        node = space._base_nodes[i]

        if check(node, filter)
            callback(node)
        end
    end

end


base_nodes(callback::Any, space::Space{Node}, filter::Any) = base_nodes(callback, space, filter, 1:length(space))


function check
end


end
