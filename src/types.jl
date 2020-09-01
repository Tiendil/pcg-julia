module Types

export Recorder, Recorders, NodeProperties


abstract type Recorder end
const Recorders = Array{<:Recorder, 1}


abstract type Cell end
const Cells = Array{<:Cell, 1}


abstract type NodeProperties end


end
