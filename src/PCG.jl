module PCG

include("types.jl")
import .Types

include("arrays_caches.jl")
import .ArraysCaches

include("geometry.jl")
import .Geometry

include("topologies/Topologies.jl")
import .Topologies

include("spaces/Spaces.jl")
import .Spaces

# include("square_greed.jl")
# import .SquareGreed

include("recorders/Recorders.jl")
import .Recorders

end
