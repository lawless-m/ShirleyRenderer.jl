module ShirleyRayTracer

using Images
using Random


export Scene, render, add!, Camera, Hitable, Hit, BVH

include("Vec3.jl")

include("Ray.jl")
include("Camera.jl")

abstract type Hitable end

@enum MaterialType _Lambertian _Metal _Dielectric _DiffuseLight _Isotropic
@enum Textures _Zero _SolidColor _Checker _Noise _TextureMap

include("Perlin.jl")
include("Textures.jl")

struct Material
	type::MaterialType
	albedo::Color
	texture::Texture
	fuzz::Float64
	ir::Float64
end

include("AaBb.jl")
include("Hitables.jl")
include("Materials.jl")
include("Scene.jl")


val(rgb) = isnan(rgb) ? 0 : clamp(sqrt(rgb), 0, 1)
rgbf8(rgb) = RGB{N0f8}(val(rgb[1]), val(rgb[2]), val(rgb[3]))

function trace_scancol(scene, x, nsamples, width, height, max_depth)
	scancol = Vector{RGB{N0f8}}(undef, height)
	ray = Ray()
	rec = Hit()

	@inbounds for y in 1:height
		rgb = zero(Color)
		@simd for i in 1:nsamples
			reset_ray!(ray, scene, (x + rand()) / width, (y + rand()) / height)
			rgb += ray_color!(rec, ray, scene, max_depth)
		end
		scancol[height-y+1] = rgbf8(rgb / nsamples)
	end
	scancol
end

function render(scene::Scene, width, height, nsamples=10, max_depth=50)
	image = Array{RGB{N0f8}, 2}(undef, height, width)
	Threads.@threads for x in 1:width
		@inbounds image[:, x] = trace_scancol(scene, x, nsamples, width, height, max_depth)
	end
	image
end


###
end
