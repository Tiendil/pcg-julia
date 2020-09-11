
module Spaces

using ..PCG.Universes
using ..PCG.Topologies
using ..PCG.Topologies.SquareGreedTopologies
using ..PCG.Topologies.HexGreedTopologies
using ..PCG.Storages.LinearStorages


# TODO: add dispatch by storage type


# TODO: does name correct
# TODO: does topology attribute requred (SquareGreedIndex should contain all required information)
function Universes.storage_index(storage::LinearStorage, topology::SquareGreedTopology, i::SquareGreedIndex)
    return LinearStorageIndex((i.y - 1) * topology.height + i.x)
end


function Universes.storage_size(::Type{LinearStorage}, topology::SquareGreedTopology)
    return topology.height * topology.width
end


# TODO: does name correct
# TODO: does topology attribute requred (HexGreedIndex should contain all required information)
function Universes.storage_index(storage::LinearStorage, topology::HexGreedTopology, i::HexGreedIndex)
    # see hex_greed_topologies.cells_hexagon
    height = topology.radius * 2 # q
    width = topology.radius  * 4 # r

    q = i.q + topology.radius
    r = i.r + topology.radius * 2

    return LinearStorageIndex((q - 1) * height + r + 1)
end


function Universes.storage_size(::Type{LinearStorage}, topology::HexGreedTopology)
    # see hex_greed_topologies.cells_hexagon
    height = topology.radius * 2 # q
    width = topology.radius  * 4 # r
    return height * width
end


end
