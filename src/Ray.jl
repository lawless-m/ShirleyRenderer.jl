
mutable struct Ray
	origin::Point3
	direction::Vec3
	time::Float64
	Ray(o, d, t) = new(o, d, t)
	Ray(o, d) = Ray(o, d, 0)
	Ray() = Ray(zero(Point3), zero(Vec3), 0)
end

at(r::Ray, t) = r.origin + t * r.direction

function set_ray!(ray::Ray, origin::Point3, direction::Vec3, time::Float64)
	ray.origin = origin
	ray.direction = direction
	ray.time = time
	ray
end

function reset_ray!(ray::Ray, scene, s::Float64, t::Float64)
	cam = scene.camera
	x, y = cam.lens_radius .* random_in_unit_disk()
	offset = cam.u * x + cam.v * y
	set_ray!(ray, cam.origin + offset, cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - cam.origin - offset, randf(cam.time0, cam.time1))
end

function ray_color!(rec, ray, scene, depth)::Tuple{Float64, Float64, Float64}
	if depth <= 0 
        return 0,0,0
	end

	hit::Bool = trace!(rec, scene.hitables, ray, 0.001, Inf)
	if !hit
		return scene.background.r, scene.background.g, scene.background.b
	end
	m = scene.materials[rec.material]
	emit = emitted(m, rec.u, rec.v, rec.p)
	scattered::Bool, attenuation = scatter!(m, ray, rec)
	if !scattered
		return emit.r, emit.g, emit.b
	end
	r::Float64, g::Float64, b::Float64 = ray_color!(rec, ray, scene, depth-1)
	emit.r + attenuation.r * r, emit.g + attenuation.g * g, emit.b + attenuation.b * b
end