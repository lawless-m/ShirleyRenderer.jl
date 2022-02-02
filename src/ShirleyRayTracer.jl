
module ShirleyRayTracer

using StaticArrays
using LinearAlgebra

const Vec3 = SVector{3, Float64}
const Point3 = SVector{3, Float64}
const Color = SVector{3, Float64}
const Scanline = Vector{Color}

include("PPM.jl")

export Scene, Camera, Point3, Vec3, Color, Scanline
export trace_scanline, render
export magnitude, add!, randf

magnitude(x,y) = sqrt(x^2 + y^2)
magnitude(x,y,z) = sqrt(x^2 + y^2 + z^2)
magnitude(v) = magnitude(v...)

randf(fmin, fmax) = fmin + (fmax-fmin)*rand()
near_zero(v) = v.x < 1e-8 && v.y < 1e-8 && v.z < 1e-8

function random_in_unit_disk() 
	x,y = randf(-1, 1), randf(-1, 1)
	while magnitude(x,y)^2 >= 1
     	x,y = randf(-1, 1), randf(-1, 1)
	end
	x,y
end

function random_in_unit_sphere() 
	x,y,z = randf(-1,1), randf(-1,1), randf(-1,1)
	while magnitude(x,y,z)^2 >= 1
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
    r_out_parallel = -sqrt(abs(1.0 - magnitude(r_out_perp)^2)) * n
    r_out_perp + r_out_parallel
end

struct Ray
	origin::Point3
	direction::Vec3
	udirection::Vec3
	tm::Float64
	Ray(o, d, m) = new(o, d, normalize(d), m)
	Ray(o, d) = Ray(o, d, 0)
	Ray() = new(Vec3(Inf, Inf, Inf), Vec3(Inf, Inf, Inf)) # a type stable sentinel instead of using nothing
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
	function Camera(lookfrom, lookat, vup, vfov, aspect_ratio, aperture, focus_dist, _time0=0, _time1=0)
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
		time0 = _time0
		time1 = _time1
		new(origin, lower_left_corner, horizontal, vertical, u, v, w, lens_radius, time0, time1)
	end
	Camera() = Camera(Point3(0,0,-1), Point3(0,0,0), Vec3(0,1,0), 40, 1, 0, 10)
end

abstract type Material end
abstract type Hitable end

include("Hitables.jl")
include("Materials.jl")

struct Scene
	camera::Camera
	hitables::Vector{Hitable}
	Scene(cam) = new(cam, Vector{Hitable}())
end

add!(s::Scene, h::Hitable) = push!(s.hitables, h)

get_ray(scene::Scene, s, t) = get_ray(scene.camera, s, t)

function get_ray(cam::Camera, s, t)
	x,y = cam.lens_radius .* random_in_unit_disk()
	offset = cam.u * x + cam.v *y
	Ray(cam.origin + offset, cam.lower_left_corner + s*cam.horizontal + t*cam.vertical - cam.origin - offset, randf(cam.time0, cam.time1))
end

function trace(scene::Scene, ray::Ray, t_min, t_max)
	closest_t = t_max
	local struck::Hitable
	
	for hitable in scene.hitables
		t = trace(hitable, ray, t_min, closest_t)
		if t >= 0
			closest_t = t
			struck = hitable
		end
	end
	
	if @isdefined struck
		Hit(struck, closest_t, ray)
	else
		Hit()
	end
end

function ray_color(scene::Scene, ray::Ray, depth)::Tuple{Float64, Float64, Float64}
	if depth <= 0 
        	return 0,0,0
	end

	hit = trace(scene, ray, 0.001, Inf)
	if isdefined(hit, :material)
		s, a = scatter(hit.material, ray, hit)
		if s.origin.x == Inf
			return 0,0,0
		end
		r,g,b = ray_color(scene, s, depth-1)
		return a[1] * r, a[2] * g, a[3] * b
	end

	t::Float64 = 0.5*(ray.udirection.y + 1.0)
	t1m = 1.0 - t
	t1m + 0.5t, t1m + 0.7t, t1m + t
end

function trace_scanline(world, y, nsamples, width, height, max_depth)
	scanline = Scanline(undef, width)
	@simd for x in 1:width
		r=g=b=0.0
		for _ in 1:nsamples
			(r,g,b) = (r,g,b) .+ ray_color(world, get_ray(world, (x + rand()) / width, (y + rand()) / height), max_depth)
		end
		@inbounds scanline[x] = Color(r/nsamples, g/nsamples, b/nsamples)
	end
	scanline
end

function render(scene::Scene, width, height, nsamples=10, max_depth=50)
	scanlines = Vector{Scanline}(undef, height)
	Threads.@threads for y in 1:height
		@inbounds scanlines[y] = trace_scanline(scene, y, nsamples, width, height, max_depth)
    end
	scanlines
end


###
end
