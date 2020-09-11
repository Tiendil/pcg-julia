module SquareGreedImages

using Images, Reel

using ...PCG.Geometry: Size, Point
using ...PCG.Types: Recorder
using ...PCG.Storages
using ...PCG.Storages.LinearStorages
using ...PCG.Topologies
using ...PCG.Topologies.SquareGreedTopologies
using ...PCG.Universes
using ...PCG.Universes: Universe
using ...PCG.Operations
using ...PCG.Recorders.GreedImages


export SquareSprite


SquareSprite(color, cell_size::Size) = Sprite(color, fill(color, (Int64(cell_size.y), Int64(cell_size.x))))


function GreedImages.node_position(recorder::GreedImageRecorder, index::SquareGreedIndex, canvas_size::Size)
    point = (Point(index) - Point(1.0, 1.0)) * recorder.cell_size
    return ceil(Int64, point) + Point(1, 1)
end


function GreedImages.canvas_size(topology::SquareGreedTopology, recorder::GreedImageRecorder)::Size
    return ceil(Int64, Size(topology.width, topology.height) * recorder.cell_size)
end


end
