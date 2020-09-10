module TurnsLogger

using ...PCG.Topologies: Topology
using ...PCG.Types: Recorder
using ...PCG.Storages
using ...PCG.Universes
using ...PCG.Universes: Universe

export TurnsLoggerRecorder


const NO_TURNS_LIMIT = -1::Int64


struct TurnsLoggerRecorder <: Recorder
    total_turns::Int64

    TurnsLoggerRecorder(total_turns::Int64=NO_TURNS_LIMIT) = new(total_turns)
end


function Universes.record_state!(universe::Universe, recorder::TurnsLoggerRecorder)
    if recorder.total_turns == NO_TURNS_LIMIT
        println("turn $(universe.turn) processed")
    else
        println("turn $(universe.turn)/$(recorder.total_turns) processed")
    end
end


function Universes.finish_recording!(recorder::TurnsLoggerRecorder)
    println("processed")
end

end
