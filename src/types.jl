module Types

export Recorder, Recorders, NodeProperties, Turn, reserve_area!, construct_element, isenabled, disable, Checkable

const Turn = Int64

abstract type Checkable end

abstract type Recorder end
const Recorders = Vector{<:Recorder}

abstract type NodeProperties end


# TODO: move somewere
function reserve_area! end


# TODO: remove
function construct_element end


# TODO: remove
function isenabled end


# TODO: remove
function disable end


end
