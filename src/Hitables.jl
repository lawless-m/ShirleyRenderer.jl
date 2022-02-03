export Sphere, MovingSphere

struct Sphere <: Hitable
	center::Point3
	radius::Float64
	material::Material
end


function hit(s::Sphere, t, ray)
	p = at(ray, t)
	outward_normal = (p - s.center) / s.radius
	ff = dot(ray.direction, outward_normal)
	norm = ff < 0 ? outward_normal : -outward_normal
	Hit(p, norm, t, ff < 0, Inf, -Inf)
end

function trace_root(oc, ray, radius, t_min, t_max)
	a = magnitudesq(ray.direction)
	half_b = dot(oc, ray.direction)
	c = magnitudesq(oc) - radius^2
	discriminant = half_b^2 - a*c
	if discriminant < 0
		return -1.0
	end

	sqrtd = sqrt(discriminant)
	root = (-half_b - sqrtd) / a
	if t_max < root || root < t_min 
		root = (-half_b + sqrtd) / a
		if t_max < root || root < t_min
			return -1.0
		end
	end

	root
end

function trace(sphere::Sphere, ray::Ray, t_min::Float64, t_max::Float64)::Float64
	oc = ray.origin - sphere.center
	trace_root(sphere, ray, oc, t_min, t_max)
end

struct MovingSphere <: Hitable
	center0::Point3
	centre1::Point3
	time0::Float64
	time1::Float64
	radius::Float64
	material::Material
end

center(ms::MovingSphere, time) = ms.center0 + ((time - ms.time0) / (ms.time1 - ms.time0))*(ms.center1 - ms.center0);

function bounding_box(m::MovingSphere, time0, time1)
	function aabb(t)
		c = center(m, t)
		AaBb(c - Vec3(m.radius, m.radius, m.radius), c + Vec3(m.radius, m.radius, m.radius))
	end
	surrounding_box(aabb(m.time0), aabb(m.time1))
end

function trace(ms::MovingSphere, ray::Ray, t_min::Float64, t_max::Float64)::Float64
	oc = ray.origin - center(ms, ray.time)
	trace_root(ms, ray, oc, t_min, t_max)
end


struct BVH <: Hitable
	left::Vector{Hitable}
	right::Vector{Hitable}
	aabb::AaBb
	BVH(l, r) = new(l, r, AaBb())
	BVH() = BVH(Vector{Hitable}(), Vector{Hitable}())
	function BVH(hitables::Vector{Hitable})
		
	end
end
