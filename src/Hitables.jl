

mutable struct Hit 
	p::Point3
	normal::Vec3
	t::Float64
	front_face::Bool
	material::Material
	Hit() = new(zero(Point3), zero(Vec3), 0, true)
end

function set_face_normal!(h::Hit, ray, outward_normal)
	h.front_face = dot(ray.direction, outward_normal) < 0
	h.normal = h.front_face ? outward_normal : -outward_normal
end

trace!(rec::Hit, h::Hitable, ray::Ray, t_min::Float64)::Bool = false

struct Sphere <: Hitable
	center::Point3
	radius::Float64
	material::Material
end

export Sphere, Hit

function trace!(rec::Hit, sphere::Sphere, ray::Ray, t_min::Float64, t_max::Float64)::Bool
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
	if t_max < root || root < t_min 
		root = (-half_b + sqrtd) / a
		if t_max < root || root < t_min
			return false
		end
	end

	rec.t = root
	rec.p = at(ray, rec.t)
	set_face_normal!(rec, ray, (rec.p - sphere.center) / sphere.radius)
	rec.material = sphere.material
	true
end
