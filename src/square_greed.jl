module SquareGreed

using ..PCG.Geometry: Point

export Cell, Cells, cells_rectangle, square_area_template

struct Cell
    x::Int32
    y::Int32
end

Cell() = Cell(0, 0)

# TODO: must differe between different topologies
const Cells = Array{Cell, 1}

Point(cell::Cell) = Point(cell.x, cell.y)

Base.:+(a::Point, b::Cell) = Point(a.x + b.x,
                                   a.y + b.y)


# TODO: rewrite to Channel or other generator
function cells_rectangle(width::Int64, height::Int64)
    # TODO: rewrite
    cells = [Cell() for _ in 1:width*height]

    i = 1

    # TODO: rewrite to single loop
    for y in 1:height,
        x in 1:width
        cells[i] = Cell(x, y)
        i += 1
    end

    return cells
end


function cells_bounding_box(cells::Cells)
    box = BoundingBox(cells[1])

    # TODO: rewrite to reduce or smth else?
    for cell in cells[2:end]
        # TODO: rewrite to convert or smth else
        box += BoundingBox(cell)
    end

    return box

end


function square_distance(a::Cell, b::Cell=Cell(0.0, 0.0))
    return max(abs(a.x-b.x), abs(a.y-b.y))
end


function square_area_template(min_distance::Int64, max_distance::Int64)
    area = Cells()

    for dx in (-max_distance):(max_distance + 1)
        for dy in (-max_distance):(max_distance + 1)

            cell = Cell(dx, dy)

            if min_distance <= square_distance(cell) <= max_distance
                push!(area, cell)
            end
        end
    end

    return area
end


end
