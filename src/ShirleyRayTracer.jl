
module ShirleyRayTracer

using Images

include("Vec3.jl")

export Scene, Camera, Point3, Vec3, Color
export trace_scanline, render
export magnitude, add!, randf

function random_in_unit_disk()
	x,y = randf(-1, 1), randf(-1, 1)
	while magnitude²(x,y) >= 1
		x,y = randf(-1, 1), randf(-1, 1)
	end
	x,y
end

function random_in_unit_sphere() 
	v = randv(-1,1)
	while magnitude²(v) >= 1
		v = randv(-1,1)
	end
	v
end

random_unit_vector() = unit(random_in_unit_sphere())

function random_in_hemisphere(normal) 
    in_unit_sphere = random_in_unit_sphere()
    dot(in_unit_sphere, normal) > 0.0 ? in_unit_sphere : -in_unit_sphere
end

mutable struct Ray
	origin::Point3
	direction::Vec3
	time::Float64
	Ray(o, d, t) = new(o, d, t)
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

		w = unit(lookfrom - lookat)
		u = unit(cross(vup, w))
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
        	return zero(Color)
	end
	hit = trace!(rec, scene, ray, 0.001, Inf)
	if !hit
		t = 0.5*(unit(ray.direction)[2] + 1.0)
		return (1.0 - t) + t * Color(0.5, 0.7, 1.0)
	end
	
	scattered, attenuation = scatter!(rec.material, ray, rec)
	if !scattered
		return Color(0,0,0)
	end
	attenuation * ray_color!(rec, ray, scene, depth-1)
end

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
