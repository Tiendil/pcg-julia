module Geometry

export Point, Points, Size, BoundingBox, xy, yx


struct Point{T}
    x::T
    y::T
end


xy(point::Point) = (point.x, point.y)

yx(point::Point) = (point.y, point.x)


Base.ceil(point::Point) = Point(ceil(point.x),
                                ceil(point.y))

Base.round(point::Point) = Point(round(point.x),
                                 round(point.y))

Base.:+(a::Point, b::Point) = Point(a.x + b.x,
                                    a.y + b.y)

Base.:-(a::Point, b::Point) = Point(a.x - b.x,
                                    a.y - b.y)

Base.:*(a::Point, b::Point) = Point(a.x * b.x,
                                    a.y * b.y)

Base.:/(a::Point, b::Int64) = Point(a.x / b,
                                    a.y / b)


function Base.ceil(::Type{T}, point::Point{B}) where {T, B}
    return Point(ceil(T, point.x),
                 ceil(T, point.y))
end


function Base.round(::Type{T}, point::Point{B}) where {T, B}
    return Point(round(T, point.x),
                 round(T, point.y))
end


const Points{T} = Vector{Point{T}}


struct Size{T}
    x::T
    y::T
end

Size(point::Point{T}) where {T} = Size(point.x, point.y)

Point(size::Size{T}) where {T} = Point(size.x, size.y)

xy(size::Size) = (size.x, size.y)

yx(size::Size) = (size.y, size.x)

Base.ceil(size::Size) = Size(ceil(size.x),
                             ceil(size.y))

Base.:+(a::Size, b::Size) = Size(a.x + b.x,
                                 a.y + b.y)

Base.:-(a::Size, b::Size) = Size(a.x - b.x,
                                 a.y - b.y)

Base.:*(a::Size, b::Size) = Size(a.x * b.x,
                                 a.y * b.y)

Base.:*(a::Size, b::Number) = Size(a.x * b,
                                   a.y * b)

Base.:/(a::Size, b::Int64) = Size(a.x / b,
                                  a.y / b)

# TODO: bad decision?
Base.:*(a::Size, b::Point) = Point(a.x * b.x,
                                   a.y * b.y)
Base.:*(a::Point, b::Size) = Point(a.x * b.x,
                                   a.y * b.y)


struct BoundingBox
    x_min::Float64
    x_max::Float64
    y_min::Float64
    y_max::Float64
end


Base.:+(a::BoundingBox, b::BoundingBox) = BoundingBox(min(a.x_min, b.x_min),
                                                      max(a.x_max, b.x_max),
                                                      min(a.y_min, b.y_min),
                                                      max(a.y_max, b.y_max))

BoundingBox() = BoundingBox(0.0, 0.0, 0.0, 0.0)

BoundingBox(point::Point) = BoundingBox(point.x, point.x + 1,
                                        point.y, point.y + 1)

BoundingBox(points::Points) = reduce(+, BoundingBox.(points), init=BoundingBox(points[1]))


Size(box::BoundingBox) = Size(box.x_max - box.x_min,
                              box.y_max - box.y_min)

function Base.ceil(::Type{T}, size::Size{B}) where {T, B}
    return Size(ceil(T, size.x),
                ceil(T, size.y))
end


end
