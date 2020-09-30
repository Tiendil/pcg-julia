module Types

export Recorder, Recorders, AbstractProperties, Turn, reserve_area!, construct_element, isenabled, disable, Checkable, neighborsof

const Turn = Int64

abstract type Checkable end

abstract type Recorder end
const Recorders = Vector{<:Recorder}

abstract type AbstractProperties end


# TODO: move somewere
function reserve_area! end


# TODO: remove
function construct_element end


# TODO: remove
function isenabled end


# TODO: remove
function disable end


# TODO: remove
function neighborsof end


end
