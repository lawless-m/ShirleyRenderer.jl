
module ShirleyRayTracer

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

export Render, Scene, Camera, add!, trace, save, Ray, Hit, DTrace

function sample(scene, ray, rec, x, y, depth)
	reset_ray!(scene.camera, ray, x, y)
	ray_color!(scene, ray, rec, depth)
end

function pixel(render, ray, rec, x, y) 
	rgb = zero(Color)
	for i in 1:render.nsamples
		xx = (x + rand()) / render.width
		yy = (y + rand()) / render.height
		rgb += sample(render.scene, ray, rec, xx, yy, render.max_depth)
	end
	rgb / render.nsamples
end

function trace_scancol!(scancol, render, rays, recs, x)
	Threads.@threads for y in 1:render.height
		scancol[render.height-y+1] = pixel(render, rays[Threads.threadid()], recs[Threads.threadid()], x, y)
	end
end


function trace(render, ch_x, ch_results)
	println("Listening")
	scancol = Vector{Color}(undef, render.height)
	rays = [Ray() for _ in 1:Threads.nthreads()]
	recs = [Hit() for _ in 1:Threads.nthreads()]
	x = take!(ch_x)
	while x > 0	
		trace_scancol!(scancol, render, rays, recs, x)
		put!(ch_results, (x, scancol))
		x = take!(ch_x)
	end
end

###
end


