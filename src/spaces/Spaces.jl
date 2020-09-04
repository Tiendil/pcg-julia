module Spaces

using ...PCG.Topologies: Topology

export Space, SpaceIndex, SpaceNode, get_node, check, set_node!, apply_changes!, record_state!, recorders

abstract type Space end
abstract type SpaceIndex end

const Turn = Int64


# TODO: mark parent classes for template parameters
struct SpaceNode{P}
    current::P
    new::P
    changed_at::Turn

    SpaceNode(current::P) where P = new{P}(current, current, 0)
    SpaceNode(current::P, turn::Turn) where P = new{P}(current, current, turn)
    SpaceNode(current::P, new::P, turn::Turn) where P = new{P}(current, new, turn)
end


# TODO: does that enough to get plain data layout in array?
const SpaceNodes{P} = Vector{SpaceNode{P}}


# TODO: specify types?

function get_node end

function set_node! end

function check end

function apply_changes! end

function recorders end


function record_state!(space::Space, topology::Topology)
    for recorder in recorders(space)
        record_state!(space, topology, recorder)
    end
end



module LinearSpaces

using ...PCG.Topologies: Topology
using ...PCG.Spaces
using ...PCG.Spaces: SpaceIndex, Space, SpaceNodes, SpaceNode, Turn
using ...PCG.Types: Recorder, Recorders

export LinearSpaceIndex, LinearSpace


struct LinearSpaceIndex <: SpaceIndex
    i::Int64
end


const LinearSpaceIndexes = Vector{LinearSpaceIndex}


mutable struct LinearSpace{P} <: Space
    nodes::SpaceNodes{P}
    new_nodes::LinearSpaceIndexes

    turn::Turn
    recorders::Recorders

    function LinearSpace(base_property::P, size::Int64, recorders::Recorders) where P
        base_node = SpaceNode(base_property)

        nodes = fill(base_node, size)

        new_nodes = LinearSpaceIndexes()
        sizehint!(new_nodes, size)

        return new{P}(nodes,
                      new_nodes,
                      0,
                      recorders)
    end
end


LinearSpace(base_property::P, size::Int64) where P = LinearSpace(base_property,
                                                                 size,
                                                                 Vector{<:Recorder}())


function Spaces.recorders(space::LinearSpace)
    return space.recorders
end


function Spaces.get_node(space::LinearSpace, i::LinearSpaceIndex)
    return space.nodes[i.i]
end


function Spaces.set_node!(space::LinearSpace, i::LinearSpaceIndex, node::SpaceNode)
    # println("----------")
    # @time space.nodes
    # @time i.i
    # @time space.nodes[i.i]
    space.nodes[i.i] = node
    push!(space.new_nodes, i)
    return
end


function Spaces.apply_changes!(space::LinearSpace, topology::Topology)

    for i in space.new_nodes
        if space.nodes[i.i].changed_at == space.turn
            space.nodes[i.i] = SpaceNode(space.nodes[i.i].new, space.turn)
        end
    end

    space.turn += 1

    resize!(space.new_nodes, 0)

    record_state!(space, topology)
end


end


end
