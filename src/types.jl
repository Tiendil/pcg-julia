module Types

export Recorder, Recorders


abstract type Recorder end
const Recorders = Array{<:Recorder, 1}


abstract type Cell end
const Cells = Array{<:Cell, 1}


end
