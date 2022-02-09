module ShirleyRayTracer

using StaticArrays
using LinearAlgebra
using Images
using Random

const Vec3 = SVector{3, Float64}
const Point3 = SVector{3, Float64}
const Color = RGB{Float64}

export Scene, Camera, Point3, Vec3, Color, Hitable, Hit, BVH
export trace_scancol, render
export magnitude, add!, randf

magnitude(x,y) = sqrt(x^2 + y^2)
magnitude(x,y,z) = sqrt(x^2 + y^2 + z^2)
magnitude(v) = magnitude(v...)

magnitudesq(x,y) = x^2 + y^2
magnitudesq(x,y,z) = x^2 + y^2 + z^2
magnitudesq(v) = magnitudesq(v...)

randf(fmin, fmax) = fmin + (fmax-fmin)*rand()
near_zero(v) = v.x < 1e-8 && v.y < 1e-8 && v.z < 1e-8

function random_in_unit_disk()
	x,y = randf(-1, 1), randf(-1, 1)
	while magnitudesq(x,y) >= 1
     	x,y = randf(-1, 1), randf(-1, 1)
	end
	x,y
end

function random_in_unit_sphere() 
	x,y,z = randf(-1,1), randf(-1,1), randf(-1,1)
	while magnitudesq(x,y,z) >= 1
		x,y,z = randf(-1,1), randf(-1,1), randf(-1,1)
	end
	Point3(x,y,z)
end

random_unit_vector() = normalize(random_in_unit_sphere())

function random_in_hemisphere(normal) 
    in_unit_sphere = random_in_unit_sphere()
    dot(in_unit_sphere, normal) > 0.0 ? in_unit_sphere : -in_unit_sphere
end


include("Ray.jl")
include("Camera.jl")

abstract type Material end
abstract type Hitable end
abstract type Texture end

include("AaBb.jl")
include("Hitables.jl")
include("Textures.jl")
include("Perlin.jl")
include("Materials.jl")
include("Scene.jl")

function trace!(rec::Hit, hitables::Vector{Hitable}, ray::Ray, t_min::Float64, t_max::Float64)
	hit::Bool = false
	for hitable in hitables
		if trace!(rec, hitable, ray, t_min, t_max)
			hit = true
		end
	end
	hit
end

rgb(r, g, b) = RGB(clamp(sqrt(r), 0, 1), clamp(sqrt(g), 0, 1), clamp(sqrt(b), 0, 1))

function trace_scancol(scene, x, nsamples, width, height, max_depth)
	scancol = Vector{RGB}(undef, height)
	rs = Vector{Float64}(undef, nsamples)
	gs = Vector{Float64}(undef, nsamples)
	bs = Vector{Float64}(undef, nsamples)

	ray = Ray()
	rec = Hit()

	@inbounds for y in 1:height
		@simd for i in 1:nsamples
			reset_ray!(ray, scene, (x + rand()) / width, (y + rand()) / height)
			rs[i], gs[i], bs[i] = ray_color!(rec, ray, scene, max_depth)
		end
		scancol[height-y+1] = rgb(sum(rs)/nsamples, sum(gs)/nsamples, sum(bs)/nsamples)
	end
	scancol
end

function render(scene::Scene, width, height, nsamples=10, max_depth=50)
	image = Array{RGB, 2}(undef, height, width)
	Threads.@threads for x in 1:width
		@inbounds image[:, x] = trace_scancol(scene, x, nsamples, width, height, max_depth)
	end
	image
end


###
end
