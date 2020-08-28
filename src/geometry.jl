module Geometry

export Point, Points, Size, BoundingBox

struct Point
    x::Float32
    y::Float32
end


Base.ceil(point::Point) = Point(ceil(point.x),
                                ceil(point.y))

Base.:-(a::Point, b::Point) = Point(a.x - b.x,
                                    a.y - b.y)

Base.:*(a::Point, b::Point) = Point(a.x * b.x,
                                    a.y * b.y)

Base.:/(a::Point, b::Int64) = Point(a.x / b,
                                    a.y / b)

const Points = Array{Point, 1}


struct Size
    x::Float32
    y::Float32
end

Base.ceil(size::Size) = Size(ceil(size.x),
                             ceil(size.y))

Base.:*(a::Size, b::Size) = Size(a.x * b.x,
                                 a.y * b.y)

# TODO: bad decision?
Base.:*(a::Size, b::Point) = Point(a.x * b.x,
                                   a.y * b.y)
Base.:*(a::Point, b::Size) = Point(a.x * b.x,
                                   a.y * b.y)


struct BoundingBox
    x_min::Float32
    x_max::Float32
    y_min::Float32
    y_max::Float32
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

end
