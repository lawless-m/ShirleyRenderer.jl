

struct Sphere <: Hitable
	center::Point3
	radius::Float64
	material::Material
end

export Sphere, Hit

function trace!(rec::Hit, sphere::Sphere, ray::Ray, t_min::Float64)::Bool
	oc = ray.origin - sphere.center
	a = magnitudesq(ray.direction)
	half_b = dot(oc, ray.direction)
	c = magnitudesq(oc) - sphere.radius^2
	discriminant = half_b^2 - a*c
	if discriminant < 0
		return false
	end

	sqrtd = sqrt(discriminant)
	root = (-half_b - sqrtd) / a
	if rec.t < root || root < t_min 
		root = (-half_b + sqrtd) / a
		if rec.t < root || root < t_min
			return false
		end
	end

	rec.t = root
	rec.p = at(ray, rec.t)
	outward_normal = (rec.p - sphere.center) / sphere.radius
	rec.front_face = dot(ray.direction, outward_normal) < 0
	rec.normal = rec.front_face < 0 ? outward_normal : -outward_normal
	rec.material = sphere.material
	true
end
