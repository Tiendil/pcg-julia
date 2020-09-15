module HexGreedImages

using Images, Reel, ImageDraw

using ...PCG.Geometry
using ...PCG.Geometry: Point
using ...PCG.Types
using ...PCG.Storages
using ...PCG.Storages.LinearStorages
using ...PCG.Topologies
using ...PCG.Topologies.HexGreedTopologies
using ...PCG.Universes
using ...PCG.Universes: Universe
using ...PCG.Operations
using ...PCG.Recorders.GreedImages


export HexSprite


# TODO: optimize algorithm
function recursive_fill!(image, point, color)

    try
        if image[point.y, point.x] == color
            return
        end
    catch e
        return
    end

    image[point.y, point.x] = color

    for delta in [Point(0, 1), Point(0, -1), Point(1, 0), Point(-1, 0)]
        recursive_fill!(image, point + delta, color)
    end

end


function HexSprite(color, cell_size::Size)
    image_size = ceil(Int64, CELL_SIZE * cell_size) + Size(2, 2)

    image = fill(RGBA(0, 0, 0, 0), yx(image_size))

    center = Point(image_size / 2)

    cell = HexGreedIndex(0, 0, 0)

    polygon = Polygon([xy(round(Int64, center + point * cell_size))
                       for point in cell_corners(cell)])

    draw!(image, polygon, color)

    recursive_fill!(image, round(Int64, center), color)

    return Sprite(color, image)
end


function GreedImages.node_position(recorder::GreedImageRecorder, index::HexGreedIndex, canvas_size::Size)
    point = Point(canvas_size / 2) + (cell_center(index) - Point(1.0, 1.0)) * recorder.cell_size
    return round(Int64, point)
end



function GreedImages.canvas_size(topology::HexGreedTopology, recorder::GreedImageRecorder)::Size
    return ceil(Int64, CELL_SIZE * recorder.cell_size * (topology.radius * 2 + 2))
end


end
