
module Operations


using ..Types
using ..Universes: Element, AreaElements

export check, Fraction, exists, not_exists, new


function check end


exists(element::Element) = convert(Bool, element)
exists(elements::AreaElements) = convert(Bool, elements)

not_exists(element::Element) = !exists(element)
not_exists(elements::AreaElements) = !exists(elements)


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


function (checker::Checkable)(element::E) where {E<:Element}
    if check(element, checker)
        return element
    end

    return disable(element)
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


function new(elements::AreaElements)
    for (i, element) in enumerate(elements)
        if isenabled(element)
            elements[i] = construct_new_element(typeof(element), element.universe, element.topology_index)
        end
    end

    return elements
end


function new(element::Element)
    if isenabled(element)
        return construct_new_element(typeof(element), element.universe, element.topology_index)
    end

    return element
end


end
