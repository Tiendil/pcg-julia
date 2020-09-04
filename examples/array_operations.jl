

struct A
    x::Int64
    y::Float32
end


struct B{P}
    aa::Vector{P}
end


x = B(fill(A(234, 1312.9), 100000))

function xx!(x, i, v)
    @time x.aa[i] = v
end

xx!(x, 2343, A(12312, 1313.0))
xx!(x, 23454, A(123154, 1313.0))
