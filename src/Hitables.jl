

struct Sphere <: Hitable
	center::Point3
	radius::Float64
	material::Material
end

export Sphere, Hit

function set_hit(scene, s::Sphere, t)
	ray = get_ray(scene)
	p = at(ray, t)
	outward_normal = (p - s.center) / s.radius
	ff = dot(ray.direction, outward_normal)
	norm = ff < 0 ? outward_normal : -outward_normal
	scene.hits[Threads.threadid()]
	set_hit(scene, p, norm, t, ff < 0)
end


function trace(sphere::Sphere, ray::Ray, t_min::Float64, t_max::Float64)::Float64
	oc = ray.origin - sphere.center
	a = magnitudesq(ray.direction)
	half_b = dot(oc, ray.direction)
	c = magnitudesq(oc) - sphere.radius^2
	discriminant = half_b^2 - a*c
	if discriminant < 0
		return Inf
	end

	sqrtd = sqrt(discriminant)
	root = (-half_b - sqrtd) / a
	if t_max < root || root < t_min 
		root = (-half_b + sqrtd) / a
		if t_max < root || root < t_min
			return Inf
		end
	end

	root
end
