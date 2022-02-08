
module ShirleyRayTracer

using StaticArrays
using LinearAlgebra
using Images

const Vec3 = SVector{3, Float64}
const Point3 = SVector{3, Float64}
const Color = RGB{Float64}

export Scene, Camera, Point3, Vec3
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

function refract(uv, n, etai_over_etat) 
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp = etai_over_etat * (uv + cos_theta*n)
    r_out_parallel = -sqrt(abs(1.0 - magnitudesq(r_out_perp))) * n
    r_out_perp + r_out_parallel
end

mutable struct Ray
	origin::Point3
	direction::Vec3
	udirection::Vec3
	time::Float64
	Ray(o, d, m) = new(o, d, normalize(d), m)
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


abstract type Material end
abstract type Hitable end

mutable struct Hit 
	p::Point3
	normal::Vec3
	t::Float64
	front_face::Bool
	material::Material
	Hit() = new(zero(Point3), zero(Vec3), 0, true)
end

include("Hitables.jl")
include("Materials.jl")

struct Scene
	camera::Camera
	hitables::Vector{Hitable}
	rays::Vector{Ray}
	hits::Vector{Hit}
	Scene(cam) = new(cam, Vector{Hitable}(), [Ray() for _ in 1:Threads.nthreads()], [Hit() for _ in 1:Threads.nthreads()])
end

add!(s::Scene, h::Hitable) = push!(s.hitables, h)

function set_ray(scene::Scene, origin::Point3, direction::Vec3, time::Float64)
	id = Threads.threadid()
	scene.rays[id].origin = origin
	scene.rays[id].direction = direction
	scene.rays[id].udirection = normalize(direction)
	scene.rays[id].time = time
	scene.rays[id]
end

get_ray(scene::Scene) = scene.rays[Threads.threadid()]

function set_ray(scene::Scene, s::Float64, t::Float64)
	cam = scene.camera
	x, y = cam.lens_radius .* random_in_unit_disk()
	offset = cam.u * x + cam.v * y
	origin = cam.origin + offset
	direction = cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - cam.origin - offset 
	set_ray(scene, origin, direction, randf(cam.time0, cam.time1))
end

get_hit(scene::Scene) = scene.hits[Threads.threadid()]
function set_hit(scene::Scene, p, normal, t, front_face) 
	id = Threads.threadid()
	scene.hits[id].p = p
	scene.hits[id].normal = normal
	scene.hits[id].t = t
	scene.hits[id].front_face = front_face
	scene.hits[id]
end
	

function trace!(rec::Hit, scene::Scene, ray::Ray, t_min::Float64, t_max::Float64)
	rec.t = t_max
	hit = false
	for hitable in scene.hitables
		if trace!(rec, hitable, ray, t_min)
			hit = true
		end
	end
	hit
end

function ray_color!(scene::Scene, ray::Ray, depth)::Tuple{Float64, Float64, Float64}
	if depth <= 0 
        	return 0,0,0
	end
	rec = Hit()
	if !trace!(rec, scene, ray, 0.001, Inf)
		t = 0.5*(ray.udirection.y + 1.0)
		t1m = 1.0 - t
		return t1m + 0.5t, t1m + 0.7t, t1m + t
	end
	
	s, a = scatter(rec.material, ray, rec)
	if s.origin.x == Inf
		return 0,0,0
	end
	r,g,b = ray_color!(scene, s, depth-1)
	a.r * r, a.g * g, a.b * b
end

val(rgb) = isnan(rgb) ? 0 : clamp(sqrt(rgb), 0, 1)
rgb(r, g, b) = RGB(val(r), val(g), val(b))

function trace_scancol(scene, x, nsamples, width, height, max_depth)
	scancol = Vector{RGB}(undef, height)
	for y in 1:height
		r=g=b=0.0
		for _ in 1:nsamples
			(r,g,b) = (r,g,b) .+ ray_color!(scene, get_ray(scene, (x + rand()) / width, (y + rand()) / height), max_depth)
		end
		@inbounds scancol[height-y+1] = rgb(r/nsamples, g/nsamples, b/nsamples)
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
