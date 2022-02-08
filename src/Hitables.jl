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
	trace_root(oc, ray, sphere.radius, t_min, t_max)
end

bounding_box(sphere::Sphere, time0, time1) = AaBb(sphere.center - Vec3(sphere.radius, sphere.radius, sphere.radius),
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
	surrounding_box(aabb(m.time0), aabb(m.time1))
end

function trace(ms::MovingSphere, ray::Ray, t_min::Float64, t_max::Float64)::Float64
	oc = ray.origin - center(ms, ray.time)
	trace_root(ms, ray, oc, t_min, t_max)
end

function box_compare(a, b, axis)
	boxa = bounding_box(a, 0, 0)
	boxb = bounding_box(b, 0, 0)
	println(stderr, "No AaBb size check")

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

bounding_box(bvh::BVH, time0, time1) = bvh.box

bounding_box(hs::Vector{Hitable}, time0, time1) = surrounding_box(map(h->bounding_box(h, time0, time1), hs))

function trace(bvh::BVH, ray::Ray, t_min::Float64, t_max::Float64)::Float64
	if !trace(bvh.box, ray, t_min, t_max)
		return -1.0
	end

	t_left = trace(bvh.left, ray, t_min, t_max)
	t_right = trace(bvh.right, ray, t_left >= 0 ? t_left, t_max)

	t_right >= 0 ? t_right : t_left
end
