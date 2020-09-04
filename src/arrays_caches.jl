module ArraysCaches

export ArraysCache, reserve!, release_all!


# TODO: refactor to compact memory storage
# TODO: refactor to universal memory cache?


struct ArraysCache{T}
    used::Vector{Bool}
    arrays::Vector{T}

    ArraysCache{T}() where T = new{T}(Vector{Bool}(), Vector{T}())
end


function reserve!(cache::ArraysCache{T}, size::Int64) where T
    for i in eachindex(cache.used)
        if !cache.used[i] && length(cache.arrays[i]) == size
            cache.used[i] = true
            return cache.arrays[i]
        end
    end

    new_array = T(UndefInitializer(), size)

    push!(cache.used, true)
    push!(cache.arrays, new_array)

    return new_array
end


function release_all!(cache::ArraysCache{T}) where T
    cache.used .= false
end


end
