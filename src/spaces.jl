
module Spaces

using ..PCG.Topologies
using ..PCG.Topologies.SquareGreedTopologies
using ..PCG.Storages.LinearStorages


# TODO: does name correct
# TODO: does topology attribute requred (SquareGreedIndex should contain all required information)
function Topologies.storage_index(topology::SquareGreedTopology, i::SquareGreedIndex)
    return LinearStorageIndex((i.y - 1) * topology.height + i.x)
end


end
