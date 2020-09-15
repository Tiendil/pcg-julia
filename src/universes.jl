
module Universes

using Setfield

using ...PCG.Types
using ...PCG.Storages: get_node, apply_changes!, Storage, StorageIndex, StorageNode
using ...PCG.Topologies: Topology, TopologyIndex, coordinates
using ...PCG.Storages
using PCG.ArraysCaches


export Element, AreaElements, Universe, finish_recording!, AreaCache, construct_current_element, construct_new_element, enabled, storage_index, storage_size, complete_turn!


abstract type AbstractUniverse end


function storage_index end
function storage_size end


struct Element{U<:AbstractUniverse, TI<:TopologyIndex, SI<:StorageIndex, P<:AbstractProperties}
    enabled::Bool # TODO: is other way exists to emulate Union{Element, Nothing} for not isbits element?
    universe::U
    topology_index::TI
    storage_index::SI
    properties::P
end



function Types.isenabled(element::Element)
    return element.enabled
end


function Types.disable(element::E) where E
    # TODO: simplify?
    return E(false, element.universe, element.topology_index, element.storage_index, element.properties)
end


Base.convert(::Type{Bool}, element::Element) = isenabled(element)


const AreaElements{U, TI, SI, N} = Vector{Element{U, TI, SI, N}}


Base.convert(::Type{Bool}, elements::AreaElements) = any(convert(Bool, element) for element in elements)

const AreaCache{U, TI, SI, P} = ArraysCache{AreaElements{U, TI, SI, P}}


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
    index = storage_index(universe.storage, universe.topology, i)
    node = get_node(universe.storage, index)
    return Element(true, universe, i, index, node.current)
end

# TODO refactor construct_*_element functions into one

# TODO: why constructor call by template variable does not see short constructor?
function Types.construct_current_element(::Type{Element{U, TI, SI, P}}, universe::U, i::TI)::Element{U, TI, SI, P} where {U<:AbstractUniverse, TI<:TopologyIndex, SI<:StorageIndex, P<:AbstractProperties}
    index = storage_index(universe.storage, universe.topology, i)
    node = get_node(universe.storage, index)
    return Element{U, TI, SI, P}(true, universe, i, index, node.current)
end


function Types.construct_new_element(::Type{Element{U, TI, SI, P}}, universe::U, i::TI)::Element{U, TI, SI, P} where {U<:AbstractUniverse, TI<:TopologyIndex, SI<:StorageIndex, P<:AbstractProperties}
    index = storage_index(universe.storage, universe.topology, i)
    node = get_node(universe.storage, index)
    return Element{U, TI, SI, P}(true, universe, i, index, node.new)
end


function Types.reserve_area!(element::Element{U, TI, SI, P}, size::Int64)::AreaElements{U, TI, SI, P} where {U, TI, SI, P}
    return reserve!(element.universe.cache::AreaCache{U, TI, SI, P}, size)
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


function (universe::Universe)(callback::Function; complete_turn::Bool=true, turns::Turn=1)
    for turn in 1:turns
        for i in coordinates(universe.topology)
            element = Element(universe, i)
            callback(element)
            release_all!(universe.cache)
        end

        if complete_turn
            complete_turn!(universe)
        end
    end
end


function ArraysCaches.release_all!(universe::Universe)
    release_all!(universe.cache)
end


# TODO: construct new node on base of already changed new node?
function Base.:<<(element::Element, new_values::NamedTuple)
    new_node = StorageNode(element.properties,
                           setproperties(element.properties, new_values),
                           element.universe.turn)

    set_node!(element.universe.storage, element.storage_index, new_node)
end


end
