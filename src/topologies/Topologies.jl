
module Topologies

export Topology, TopologyIndex, coordinates, is_valid, index_type


abstract type Topology end
abstract type TopologyIndex end


# TODO: specify types

function coordinates end

function is_valid end

function index_type end


include("square_greed_topologies.jl")

include("hex_greed_topologies.jl")


end
