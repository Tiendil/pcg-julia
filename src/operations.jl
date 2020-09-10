
module Operations


using ..Types
using ..Universes: Element, AreaElements

export check, Fraction


function check end


function Base.count(elements::AreaElements)
    counter = 0

    for element in elements
        if isenabled(element)
            counter += 1
        end
    end

    return counter
end


struct Fraction <: Checkable
    border::Float32
end


function check(element::Element, parameters::Fraction)
    return rand(Float32) < parameters.border
end


# TODO: must return element, to allow chain checks
function (checker::Checkable)(element::E) where {E<:Element}
    return check(element, checker)
end


function (checker::Checkable)(elements::Vector{E}) where {E<:Element}
    # TODO: replace with boolean template assigment

    for (i, e) in enumerate(elements)
        if isenabled(e) && !check(e, checker)
            elements[i] = disable(elements[i])
        end
    end

    return elements
end


end
