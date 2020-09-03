module Types

export Recorder, Recorders, NodeProperties


abstract type Recorder end
const Recorders = Vector{<:Recorder}


abstract type NodeProperties end


end
