module HexGreedImages

using Images, Reel, ImageDraw

using ...PCG.Geometry: Size, Point, xy
using ...PCG.Types: Recorder
using ...PCG.Storages
using ...PCG.Storages.LinearStorages
using ...PCG.Topologies
using ...PCG.Topologies.HexGreedTopologies
using ...PCG.Universes
using ...PCG.Universes: Universe
using ...PCG.Operations
using ...PCG.Recorders.GreedImages


# export HexSprite

println("!!!!!!!!!!!!!!!")

2 / 0

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


# function HexSprite(color, cell_size::Size)
#     sprite_size = CELL_SIZE * cell_size

#     image_size = ceil(Int64, sprite_size)

#     image = fill(RGBA(0, 0, 0, 0), (image_size.y, image_size.x))

#     center = image_size / 2

#     cell = HexGreedIndex(0, 0, 0)

#     polygon = Polygon([xy(ceil(Int64, Point(center.x, center.y) + point * cell_size))
#                        for point in cell_corners(cell)])

#     draw!(image, polygon, color)

#     recursive_fill!(image, ceil(Int64, Point(center.x, center.y)), color)

#     return Sprite(color, image)
# end


# function GreedImages.node_position(recorder::GreedImageRecorder, index::HexGreedIndex, canvas_size::Size)
#     point = Point(canvas_size.x / 2, canvas_size.y / 2) + (cell_center(index) - Point(1.0, 1.0)) * recorder.cell_size
#     return ceil(Int64, point)
# end


function GreedImages.canvas_size(topology::HexGreedTopology, recorder::GreedImageRecorder)::Size
    return ceil(Int64, CELL_SIZE * recorder.cell_size * (topology.radius * 2 + 2))
end


println(canvas_size)


end
