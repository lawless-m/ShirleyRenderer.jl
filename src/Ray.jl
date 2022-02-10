
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

function reset_ray!(scene, ray::Ray, s::Float64, t::Float64)
	cam = scene.camera
	x, y = cam.lens_radius .* random_in_unit_disk()
	offset = cam.u * x + cam.v * y
	set_ray!(ray, cam.origin + offset, cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - cam.origin - offset, randf(cam.time0, cam.time1))
end

function ray_color!(scene, ray::Ray, rec, depth::Int)::Tuple{Float64, Float64, Float64}
	if depth <= 0 
        return Color(0,0,0)
	end

	hit::Bool = trace!(scene.hitables, ray, rec, 0.001, Inf)
	if !hit
		return scene.background
	end
	emit = emitted(scene, rec, rec.u, rec.v, rec.p)
	scattered::Bool, attenuation = scatter!(scene, ray, rec)
	if !scattered
		return emit
	end
	emit + attenuation * ray_color!(scene, ray, rec, depth-1)
end

