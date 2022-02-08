

mutable struct Ray
	origin::Point3
	direction::Vec3
	udirection::Vec3
	time::Float64
	Ray(o, d, t) = new(o, d, normalize(d), t)
	Ray(o, d) = Ray(o, d, 0)
	Ray() = new(Vec3(Inf, Inf, Inf), Vec3(Inf, Inf, Inf)) # a type stable sentinel instead of using nothing
end

at(r::Ray, t) = r.origin + t * r.direction

function set_ray!(ray::Ray, origin::Point3, direction::Vec3, time::Float64)
	ray.origin = origin
	ray.direction = direction
	ray.udirection = normalize(direction)
	ray.time = time
	ray
end

function reset_ray!(ray::Ray, scene, s::Float64, t::Float64)
	cam = scene.camera
	x, y = cam.lens_radius .* random_in_unit_disk()
	offset = cam.u * x + cam.v * y
	set_ray!(ray, cam.origin + offset, cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - cam.origin - offset, randf(cam.time0, cam.time1))
end
