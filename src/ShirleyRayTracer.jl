
module ShirleyRayTracer

using Distributed

include("Vec3.jl")
include("Ray.jl")
include("Camera.jl")

abstract type Hitable end
struct Render
	scene
	width
	height
	nsamples
	max_depth
end


include("Materials.jl")
include("Hitables.jl")
include("Scene.jl")

export Render, Scene, Camera, add!, trace, save, Dtrace

function sample(scene, ray, rec, x, y, depth)
	reset_ray!(scene.camera, ray, x, y)
	ray_color!(scene, ray, rec, depth)
end

function trace_scancol(render, ray, rec, x)
	scancol = Vector{Float64}(undef, render.height)
	rgbs = Vector{Color}(undef, render.nsamples)

	for y in 1:render.height
		for i in 1:render.nsamples
			xx = (x + rand()) / render.width
			yy = (y + rand()) / render.height
			rgbs[i] = sample(render.scene, ray, rec, xx, yy, render.max_depth)
		end
		scancol[render.height-y+1] = sum(rgbs) / render.nsamples
	end
	scancol
end

function trace(render)
	image = Array{Float64, 2}(undef, render.height, render.width)
	rays = [Ray() for _ in 1:Threads.nthreads()]
	recs = [Hit() for _ in 1:Threads.nthreads()]
	Threads.@threads for x in 1:render.width
		@inbounds image[:, x] = trace_scancol(render, rays[Threads.threadid()], recs[Threads.threadid()], x)
	end
	image
end


function trace(render, ch_x, ch_results)
	println("Listening on $(myid())")
	scancol = Vector{Float64}(undef, render.height)
	ray = Ray()
	rec = Hit()
	x = 1
	while x > 0	
		x = take!(ch_x)
		rgbs = Vector{Color}(undef, samples)
		put!(ch_results, (x, trace_scancol(scene, samples, x, width, height, depth)))
	end
end

function Dtrace(render)
	ch_x = RemoteChannel(()->Channel{Int}(render.width))
	ch_results = RemoteChannel(()->Channel{Tuple}(1))

	@async foreach(x->put!(ch_x, x), 1:render.width)

	for p in workers() # start tasks on the workers to process requests in parallel
           remote_do(trace, p, render, ch_x, ch_results)
        end

	image = Array{Float64, 2}(undef, render.height, render.width)
		
	while (r = take!(ch_results))
       		@inbounds image[:, r[1]] = r[2]
        end
        image
end
	

###
end
