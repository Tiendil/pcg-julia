
module Universes

using Setfield

using ...PCG.Types
using ...PCG.Storages: get_node, apply_changes!, Storage, StorageIndex, StorageNode
using ...PCG.Topologies: Topology, TopologyIndex, coordinates, storage_index
using ...PCG.Storages
using PCG.ArraysCaches


export Element, AreaElements, Universe, finish_recording!, AreaCache, construct_element, enabled


abstract type AbstractUniverse end


struct Element{U<:AbstractUniverse, TI<:TopologyIndex, SI<:StorageIndex, N<:StorageNode}
    enabled::Bool # TODO: is other way exists to emulate Union{Element, Nothing} for not isbits element?
    universe::U
    topology_index::TI
    storage_index::SI
    node::N
end


function Types.isenabled(element::Element)
    return element.enabled
end


function Types.disable(element::E) where E
    # TODO: simplify?
    return E(false, element.universe, element.topology_index, element.storage_index, element.node)
end


const AreaElements{U, TI, SI, N} = Vector{Element{U, TI, SI, N}}

const AreaCache{U, TI, SI, N} = ArraysCache{AreaElements{U, TI, SI, N}}


mutable struct Universe{S<:Storage, T<:Topology} <: AbstractUniverse
    storage::S
    topology::T

    turn::Turn
    recorders::Recorders

    cache::Union{AreaCache, Nothing}
end


Universe(storage::S, topology::T, recorders::Recorders) where {S, T} = Universe(storage,
                                                                              topology,
                                                                              0,
                                                                              recorders,
                                                                              nothing)


# TODO: lazy calculation of fields "storage_index" & "node"?
function Element(universe::Universe, i::TI) where {TI<:TopologyIndex}
    index = storage_index(universe.topology, i)
    node = get_node(universe.storage, index)
    return Element(true, universe, i, index, node)
end


# TODO: why constructor call by template variable does not see short constructor?
function Types.construct_element(::Type{Element{U, TI, SI, N}}, universe::U, i::TI)::Element{U, TI, SI, N} where {U<:AbstractUniverse, TI<:TopologyIndex, SI<:StorageIndex, N<:StorageNode}
    index = storage_index(universe.topology, i)
    node = get_node(universe.storage, index)
    return Element{U, TI, SI, N}(true, universe, i, index, node)
end


function Types.reserve_area!(element::Element{U, TI, SI, N}, size::Int64)::AreaElements{U, TI, SI, N} where {U, TI, SI, N}
    return reserve!(element.universe.cache::AreaCache{U, TI, SI, N}, size)
end


function recorders(universe::Universe)
    return universe.recorders
end


function complete_turn!(universe::Universe)

    apply_changes!(universe.storage, universe.turn)

    universe.turn += 1

    record_state!(universe)
end


function record_state!(universe::Universe)
    for recorder in recorders(universe)
        record_state!(universe, recorder)
    end
end


function finish_recording!(universe::Universe)
    for recorder in recorders(universe)
        finish_recording!(recorder)
    end
end


function (universe::Universe)(callback::Function; complete_turn::Bool=true)
    for i in coordinates(universe.topology)
        element = Element(universe, i)
        callback(element)
        release_all!(universe.cache)
    end

    if complete_turn
        complete_turn!(universe)
    end
end


function ArraysCaches.release_all!(universe::Universe)
    release_all!(universe.cache)
end


# TODO: construct new node on base of already changed new node?
function Base.:<<(element::Element, new_values::NamedTuple)
    new_node = StorageNode(element.node.current,
                           setproperties(element.node.current, new_values),
                           element.universe.turn)

    set_node!(element.universe.storage, element.storage_index, new_node)
end


end
