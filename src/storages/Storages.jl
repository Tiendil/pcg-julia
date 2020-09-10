module Storages

using ...PCG.Types: Turn

export Storage, StorageIndex, StorageNode, get_node, set_node!, apply_changes! #, record_state!, recorders

abstract type Storage end
abstract type StorageIndex end


# TODO: mark parent classes for template parameters
struct StorageNode{P}
    current::P
    new::P
    changed_at::Turn

    StorageNode(current::P) where P = new{P}(current, current, 0)
    StorageNode(current::P, turn::Turn) where P = new{P}(current, current, turn)
    StorageNode(current::P, new::P, turn::Turn) where P = new{P}(current, new, turn)
end


# TODO: does that enough to get plain data layout in array?
const StorageNodes{P} = Vector{StorageNode{P}}


# TODO: specify types?

function get_node end

function set_node! end

function apply_changes! end


module LinearStorages

using ...PCG.Storages
using ...PCG.Storages: StorageIndex, Storage, StorageNodes, StorageNode, Turn

export LinearStorageIndex, LinearStorage


struct LinearStorageIndex <: StorageIndex
    i::Int64
end


const LinearStorageIndexes = Vector{LinearStorageIndex}


struct LinearStorage{P} <: Storage
    nodes::StorageNodes{P}
    new_nodes::LinearStorageIndexes

    function LinearStorage(base_properties::P, size::Int64) where P
        base_node = StorageNode(base_properties)

        nodes = fill(base_node, size)

        new_nodes = LinearStorageIndexes()
        sizehint!(new_nodes, size)

        return new{P}(nodes, new_nodes)
    end
end


function Storages.get_node(storage::LinearStorage, i::LinearStorageIndex)
    return storage.nodes[i.i]
end


function Storages.set_node!(storage::LinearStorage, i::LinearStorageIndex, node::StorageNode)
    storage.nodes[i.i] = node
    push!(storage.new_nodes, i)
    return
end


function Storages.apply_changes!(storage::LinearStorage, turn::Turn)
    for i in storage.new_nodes
        if storage.nodes[i.i].changed_at == turn
            storage.nodes[i.i] = StorageNode(storage.nodes[i.i].new, turn)
        end
    end

    resize!(storage.new_nodes, 0)
end


end


end
