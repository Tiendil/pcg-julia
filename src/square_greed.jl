module SquareGreed

using ..PCG.Geometry: Point
using ..PCG.Types: Cell, Cells

export SquareCell, SquareCells, cells_rectangle, square_area_template

struct SquareCell <: Cell
    x::Int32
    y::Int32
end

const SquareCells = Array{SquareCell, 1}

SquareCell() = SquareCell(0, 0)

# TODO: move somewere or remove
Point(cell::SquareCell) = Point(cell.x, cell.y)

Base.:+(a::Point, b::SquareCell) = Point(a.x + b.x,
                                         a.y + b.y)


# TODO: rewrite to Channel or other generator
function cells_rectangle(width::Int64, height::Int64)
    # TODO: rewrite
    cells = [SquareCell() for _ in 1:width*height]

    i = 1

    # TODO: rewrite to single loop
    for y in 1:height,
        x in 1:width
        cells[i] = SquareCell(x, y)
        i += 1
    end

    return cells
end


function cells_bounding_box(cells::SquareCells)
    box = BoundingBox(cells[1])

    # TODO: rewrite to reduce or smth else?
    for cell in cells[2:end]
        # TODO: rewrite to convert or smth else
        box += BoundingBox(cell)
    end

    return box

end


function square_distance(a::SquareCell, b::SquareCell=SquareCell(0.0, 0.0))
    return max(abs(a.x-b.x), abs(a.y-b.y))
end


function square_area_template(min_distance::Int64, max_distance::Int64)
    area = SquareCells()

    for dx in (-max_distance):(max_distance + 1)
        for dy in (-max_distance):(max_distance + 1)

            cell = SquareCell(dx, dy)

            if min_distance <= square_distance(cell) <= max_distance
                push!(area, cell)
            end
        end
    end

    return area
end


end
