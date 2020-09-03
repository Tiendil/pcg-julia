module TurnsLogger

using ...PCG.Topologies: Topology
using ...PCG.Types: Recorder
using ...PCG.Spaces

export TurnsLoggerRecorder


const NO_TURNS_LIMIT = -1::Int64


mutable struct TurnsLoggerRecorder <: Recorder
    turn_number::Int64
    total_turns::Int64

    TurnsLoggerRecorder(turn_number::Int64=0, total_turns::Int64=NO_TURNS_LIMIT) = new(turn_number, total_turns)
end


function Spaces.record_state!(space::Space, topology::Topology, recorder::TurnsLoggerRecorder)
    recorder.turn_number += 1

    if recorder.total_turns == NO_TURNS_LIMIT
        println("turn $(recorder.turn_number) processed")
    else
        println("turn $(recorder.turn_number)/$(recorder.total_turns) processed")
    end
end

end
