export Hit, Sphere, MovingSphere, BVH

mutable struct Hit 
	p::Point3
	normal::Vec3
	t::Float64
	front_face::Bool
	u::Float64
	v::Float64
	material::Material
	Hit() = new(zero(Point3), zero(Vec3), 0, true, 0, 0)
end

trace!(rec::Hit, h::Hitable, ray::Ray, t_min::Float64, t_max::Float64)::Bool = false

function set_face_normal!(h::Hit, ray, outward_normal)
	h.front_face = dot(ray.direction, outward_normal) < 0
	h.normal = h.front_face ? outward_normal : -outward_normal
end

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

function trace_root(oc, ray, radius, t_min, t_max)::Float64
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

function trace!(rec::Hit, sphere::Sphere, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	oc = ray.origin - sphere.center
	root = trace_root(oc, ray, sphere.radius, t_min, t_max)
	if root < 0 return false end

	rec.t = root
	rec.p = at(ray, rec.t)
	set_face_normal!(rec, ray, (rec.p - sphere.center) / sphere.radius)
	rec.material = sphere.material
	true
end

bounding_box(sphere::Sphere, time0, time1) = true, AaBb(sphere.center - Vec3(sphere.radius, sphere.radius, sphere.radius),
		sphere.center + Vec3(sphere.radius, sphere.radius, sphere.radius))

struct MovingSphere <: Hitable
	center0::Point3
	center1::Point3
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
	true, surrounding_box(aabb(m.time0), aabb(m.time1))
end

function trace!(rec::Hit, ms::MovingSphere, ray::Ray, t_min::Float64, t_max::Float64)
	oc = ray.origin - center(ms, ray.time)
	root = trace_root(oc, ray, ms.radius, t_min, t_max)
	if root < 0 return false end

	rec.t = root
	rec.p = at(ray, rec.t)
	set_face_normal!(rec, ray, (rec.p - center(ms, ray.time)) / ms.radius)
	rec.material = ms.material
	true
end

function box_compare(a, b, axis)
	fa, boxa = bounding_box(a, 0, 0)
	fb, boxb = bounding_box(b, 0, 0)
	if !(fa && fb)
		println(stderr, "No bounding box in bvh_node constructor.")

	end
	boxa.min[axis] < boxb.min[axis]
end

struct BVH <: Hitable
	left::Vector{Hitable}
	right::Vector{Hitable}
	box::AaBb
	BVH(l, r) = new(l, r, AaBb())
	BVH() = BVH(Vector{Hitable}(), Vector{Hitable}())
	function BVH(hitables::Vector{Hitable}, time0, time1)

		ltfn(axis) = (a,b)->box_compare(a, b, axis)

		sort!(hitables, lt=ltfn(rand([1,2,3])))

		if length(hitables) < 2
			left = right = hitables
		else
			mid = floor(Int, length(hitables)/2)	
			left = hitables[1:mid]
			right = hitables[mid+1:end]
		end
		println(stderr, "No AaBb size check")
		new(left, right, surrounding_box(bounding_box(left, time0, time1), bounding_box(right, time0, time1)))
	end
end

bounding_box(bvh::BVH, time0, time1) = true, bvh.box

bounding_box(hs::Vector{Hitable}, time0, time1) = true, surrounding_box(map(h->bounding_box(h, time0, time1), hs))

function trace!(rec::Hit, bvh::BVH, ray::Ray, t_min::Float64, t_max::Float64)
	if !trace!(rec, bvh.box, ray, t_min, t_max)
		return false
	end

	hit_left = trace!(rec, bvh.left, ray, t_min, t_max)
	hit_right = trace!(rec, bvh.right, ray, t_min, hit_left ? rec.t : t_max)

	hit_left || hit_right
end
