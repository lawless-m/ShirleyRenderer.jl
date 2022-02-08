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

function trace!(rec::Hit, bvh::BVH, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	if !trace!(rec, bvh.box, ray, t_min, t_max)
		return false
	end

	hit_left = trace!(rec, bvh.left, ray, t_min, t_max)
	hit_right = trace!(rec, bvh.right, ray, t_min, hit_left ? rec.t : t_max)

	hit_left || hit_right
end

function set_face_normal!(h::Hit, ray, outward_normal)
	h.front_face = dot(ray.direction, outward_normal) < 0
	h.normal = h.front_face ? outward_normal : -outward_normal
end

struct XYRect <: Hitable
	x0
	x1
	y0
	y1
	k
	material
end

bounding_box(r::XYRect, time0, time1) = true, AaBb(Point3(r.x0, r.y0, r.k-0.0001), Point3(r.x1, r.y1, r.k+0.001))

function trace!(rec::Hit, xyr::XYRect, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	t = (xyr.k - ray.origin.z) / r.direction.z
	if t < t_min || t > t_max
		return false
	end

	x = ray.origin.x + t*ray.direction.x
	y = ray.origin.y + t*ray.direction.y
	if x < xyr.x0 || x > xyr.x1 || y < xyr.y0 || y > xyr.y1
		return false
	end

	rec.u = (x - xyr.x0) / (xyr.x1 - xyr.x0)
	rec.v = (y - xyr.y0) / (xyr.y1 - xyr.y0)
	rec.t = t
	set_face_normal!(ray, Vec3(0,0,1))
	rec.material = xyr.material
	rec.p = at(ray, t)

	true
end

struct XZRect <: Hitable
	x0
	x1
	z0
	z1
	k
	material
end

bounding_box(r::XZRect, time0, time1) = true, AaBb(Point3(r.x0, r.k-0.0001, r.z0), Point3(r.x1, r.k+0.0001, r.z1))

function trace!(rec::Hit, xzr::XYRect, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	t = (xzr.k - ray.origin.y) / r.direction.y
	if t < t_min || t > t_max
		return false
	end

	x = ray.origin.x + t*ray.direction.x
	z = ray.origin.z + t*ray.direction.z
	if x < xzr.x0 || x > xzr.x1 || z < xzr.z0 || z > xzr.z1
		return false
	end

	rec.u = (x - xzr.x0) / (xzr.x1 - xzr.x0)
	rec.v = (z - xzr.z0) / (xzr.z1 - xzr.z0)
	rec.t = t
	set_face_normal!(ray, Vec3(0,1,0))
	rec.material = xzr.material
	rec.p = at(ray, t)

	true
end

struct YZRect <: Hitable
	y0
	y1
	z0
	z1
	k
	material
end

bounding_box(r::YZRect, time0, time1) = true, AaBb(Point3(r.k-0.0001, r.y0, r.z0), Point3(r.k+0.0001, r.y1, r.z1))

function trace!(rec::Hit, yzr::YZRect, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	t = (yzr.k - ray.origin.x) / r.direction.x
	if t < t_min || t > t_max
		return false
	end

	y = ray.origin.y + t*ray.direction.y
	z = ray.origin.z + t*ray.direction.z
	if y < yzr.y0 || y > yzr.y1 || z < yzr.z0 || z > yzr.z1
		return false
	end

	rec.u = (y - yzr.y0) / (yzr.y1 - yzr.y0)
	rec.v = (z - yzr.z0) / (yzr.z1 - yzr.z0)
	rec.t = t
	set_face_normal!(ray, Vec3(1,0,0))
	rec.material = yzr.material
	rec.p = at(ray, t)

	true
end

struct Box <: Hitable
	box_min
	box_max
	sides
	function Box(p0, p1, m)
		sides = Vector{Hitable}(undef, 6)
		sides[1] = XYRect(p0.x, p1.x, p0.y, p1.y, p1.z), m)
		sides[2] = XYRect(p0.x, p1.x, p0.y, p1.y, p0.z), m)

		sides[3] = XZRect(p0.x, p1.x, p0.z, p1.z, p1.y), m)
		sides[4] = XZRect(p0.x, p1.x, p0.z, p1.z, p0.y), m)

		sides[5] = YZRect(p0.y, p1.y, p0.z, p1.z, p1.x), m)
		sides[6] = YZRect(p0.y, p1.y, p0.z, p1.z, p0.x), m)
		
		new(p0, p1, sides)
	end
end

trace!(rec::Hit, b::Box, ray::Ray, t_min::Float64, t_max::Float64)::Bool = trace!(rec::Hit, b.sides, ray, t_min, t_max)










