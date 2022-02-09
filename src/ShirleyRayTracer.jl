
module ShirleyRayTracer

using StaticArrays
using LinearAlgebra
using Images

const Vec3 = SVector{3, Float64}
const Point3 = SVector{3, Float64}
const Color = RGB{Float64}

export Scene, Camera, Point3, Vec3, Color
export trace_scanline, render
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

mutable struct Ray
	origin::Point3
	direction::Vec3
	udirection::Vec3
	time::Float64
	Ray(o, d, t) = new(o, d, normalize(d), t)
	Ray(o, d) = Ray(o, d, 0)
	Ray() = Ray(zero(Point3), zero(Vec3))
end

at(r::Ray, t) = r.origin + t * r.direction

struct Camera
	origin::Point3
	lower_left_corner::Point3
	horizontal::Vec3
	vertical::Vec3
	u::Vec3
	v::Vec3
	w::Vec3
	lens_radius::Float64
	time0::Float64
	time1::Float64
	function Camera(lookfrom, lookat, vup, vfov, aspect_ratio, aperture, focus_dist, time0=0, time1=0)
		viewport_height = 2.0 * tan(deg2rad(vfov)/2)
		viewport_width = aspect_ratio * viewport_height

		w = normalize(lookfrom - lookat)
		u = normalize(cross(vup, w))
		v = cross(w, u)

		origin = lookfrom
		horizontal = focus_dist * viewport_width * u
		vertical = focus_dist * viewport_height * v
		lower_left_corner = origin - horizontal/2 - vertical/2 - focus_dist*w

		lens_radius = aperture / 2
		new(origin, lower_left_corner, horizontal, vertical, u, v, w, lens_radius, time0, time1)
	end
	Camera() = Camera(Point3(0,0,-1), Point3(0,0,0), Vec3(0,1,0), 40, 1, 0, 10)
end

abstract type Hitable end

include("Materials.jl")
include("Hitables.jl")

struct Scene
	camera::Camera
	hitables::Vector{Hitable}
	Scene(cam) = new(cam, Vector{Hitable}())
end

add!(s::Scene, h::Hitable) = push!(s.hitables, h)

function set_ray!(ray, origin, direction, time)
	ray.origin = origin
	ray.direction = direction
	ray.time = time
	ray
end

function reset_ray!(ray::Ray, scene::Scene, s::Float64, t::Float64)
	cam = scene.camera
	x, y = cam.lens_radius .* random_in_unit_disk()
	offset = cam.u * x + cam.v * y
	set_ray!(ray, cam.origin + offset, cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - cam.origin - offset, randf(cam.time0, cam.time1))
end

function trace!(rec::Hit, scene::Scene, ray::Ray, t_min::Float64, t_max::Float64)
	hit = false
	for hitable in scene.hitables
		if trace!(rec, hitable, ray, t_min, t_max)
			hit = true
		end
	end
	hit
end

function ray_color!(rec::Hit, ray::Ray, scene::Scene, depth)::Tuple{Float64, Float64, Float64}
	if depth <= 0 
        	return 0,0,0
	end
	hit = trace!(rec, scene, ray, 0.001, Inf)
	if !hit
		t = 0.5*(normalize(ray.direction).y + 1.0)
		t1m = 1.0 - t
		return t1m + 0.5t, t1m + 0.7t, t1m + t
	end
	
	scattered, a = scatter!(rec.material, ray, rec)
	if !scattered
		return 0,0,0
	end
	r,g,b = ray_color!(rec, ray, scene, depth-1)
	a.r * r, a.g * g, a.b * b
end

val(rgb) = isnan(rgb) ? 0 : clamp(sqrt(rgb), 0, 1)
rgb(r, g, b) = RGB{N0f8}(val(r), val(g), val(b))

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
