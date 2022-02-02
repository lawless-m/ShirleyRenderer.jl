
struct Sphere <: Hitable
	center::Point3
	radius::Float64
	material::Material
end

export Sphere, Hit

struct Hit 
	p::Point3
	normal::Vec3
	material::Material
	t::Float64
	front_face::Bool
	function Hit(s::Sphere, t, ray)
		p = at(ray, t)
		outward_normal = (p - s.center) / s.radius
		ff = dot(ray.direction, outward_normal)
		norm = ff < 0 ? outward_normal : -outward_normal
		new(p, norm, s.material, t, ff < 0)
	end
	Hit() = new()
end

function trace(sphere::Sphere, ray::Ray, t_min, t_max)
	oc = ray.origin - sphere.center
	a = magnitude(ray.direction)^2
	half_b = dot(oc, ray.direction)
	c = magnitude(oc)^2 - sphere.radius^2
	discriminant = half_b^2 - a*c
	if discriminant < 0
		return -1
	end

	sqrtd = sqrt(discriminant)
	root = (-half_b - sqrtd) / a
	if root < t_min || t_max < root
		root = (-half_b + sqrtd) / a
		if root < t_min || t_max < root
			return -1
		end
	end

	root
end
