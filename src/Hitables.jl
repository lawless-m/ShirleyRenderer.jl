export Hit, Sphere, MovingSphere, BVH, XYRect, XZRect, YZRect, Box, RotateY, Translate, ConstantMedium

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

function set_face_normal!(rec::Hit, ray::Ray, outward_normal::Vec3)
	rec.front_face = dot(ray.direction, outward_normal) < 0
	rec.normal = rec.front_face ? outward_normal : -outward_normal
end

struct Sphere <: Hitable
	center::Point3
	radius::Float64
	material::Material
end

function trace_root(oc, ray, radius, t_min, t_max)::Float64
	a = magnitude²(ray.direction)
	half_b = dot(oc, ray.direction)
	c = magnitude²(oc) - radius^2
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

bounding_box(sphere::Sphere, time0, time1) = true, AaBb(sphere.center - Vec3(sphere.radius), sphere.center + Vec3(sphere.radius))

struct MovingSphere <: Hitable
	center0::Point3
	center1::Point3
	time0::Float64
	time1::Float64
	radius::Float64
	material::Material
end

center(ms::MovingSphere, time) = ms.center0 + ((time - ms.time0) / (ms.time1 - ms.time0))*(ms.center1 - ms.center0)

function bounding_box(m::MovingSphere, time0, time1)
	function aabb(t)
		c = center(m, t)
		AaBb(c - Vec3(m.radius, m.radius, m.radius), c + Vec3(m.radius, m.radius, m.radius))
	end
	true, surrounding_box([aabb(m.time0), aabb(m.time1)])
end

function trace!(rec::Hit, ms::MovingSphere, ray::Ray, t_min::Float64, t_max::Float64)::Bool
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
		println(stderr, "No AaBb size check in BVH")
		new(left, right, surrounding_box([bounding_box(left, time0, time1)[2], bounding_box(right, time0, time1)[2]]))
	end
end

bounding_box(bvh::BVH, time0, time1) = true, bvh.box

bounding_box(hs::Vector{Hitable}, time0, time1) = true, surrounding_box(map(h->bounding_box(h, time0, time1)[2], hs))

function trace!(rec::Hit, bvh::BVH, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	if !trace!(rec, bvh.box, ray, t_min, t_max)
		return false
	end

	hit_left = trace!(rec, bvh.left, ray, t_min, t_max)
	hit_right = trace!(rec, bvh.right, ray, t_min, hit_left ? rec.t : t_max)

	hit_left || hit_right
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
	t = (xyr.k - ray.origin[2]) / ray.direction[2]
	if t < t_min || t > t_max
		return false
	end

	x = ray.origin[1] + t*ray.direction[1]
	y = ray.origin[2] + t*ray.direction[2]
	if x < xyr.x0 || x > xyr.x1 || y < xyr.y0 || y > xyr.y1
		return false
	end

	rec.u = (x - xyr.x0) / (xyr.x1 - xyr.x0)
	rec.v = (y - xyr.y0) / (xyr.y1 - xyr.y0)
	rec.t = t
	set_face_normal!(rec, ray, Vec3(0,0,1))
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

function trace!(rec::Hit, xzr::XZRect, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	t = (xzr.k - ray.origin[2]) / ray.direction[2]
	if t < t_min || t > t_max
		return false
	end

	x = ray.origin[1] + t*ray.direction[1]
	z = ray.origin[3] + t*ray.direction[3]
	if x < xzr.x0 || x > xzr.x1 || z < xzr.z0 || z > xzr.z1
		return false
	end

	rec.u = (x - xzr.x0) / (xzr.x1 - xzr.x0)
	rec.v = (z - xzr.z0) / (xzr.z1 - xzr.z0)
	rec.t = t
	set_face_normal!(rec, ray, Vec3(0,1,0))
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
	t = (yzr.k - ray.origin[1]) / ray.direction[1]
	if t < t_min || t > t_max
		return false
	end

	y = ray.origin[2] + t*ray.direction[2]
	z = ray.origin[3] + t*ray.direction[3]
	if y < yzr.y0 || y > yzr.y1 || z < yzr.z0 || z > yzr.z1
		return false
	end

	rec.u = (y - yzr.y0) / (yzr.y1 - yzr.y0)
	rec.v = (z - yzr.z0) / (yzr.z1 - yzr.z0)
	rec.t = t
	set_face_normal!(rec, ray, Vec3(1,0,0))
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
		sides[1] = XYRect(p0[1], p1[1], p0[2], p1[2], p1[3], m)
		sides[2] = XYRect(p0[1], p1[1], p0[2], p1[2], p0[3], m)

		sides[3] = XZRect(p0[1], p1[1], p0[3], p1[2], p1[2], m)
		sides[4] = XZRect(p0[1], p1[1], p0[3], p1[3], p0[2], m)

		sides[5] = YZRect(p0[2], p1[2], p0[3], p1[3], p1[1], m)
		sides[6] = YZRect(p0[2], p1[2], p0[3], p1[3], p0[1], m)
		
		new(p0, p1, sides)
	end
end

trace!(rec::Hit, b::Box, ray::Ray, t_min::Float64, t_max::Float64)::Bool = trace!(rec::Hit, b.sides, ray, t_min, t_max)

bounding_box(b::Box, time0, time1) = true, AaBb(b.box_min, b.box_max)

struct RotateY <: Hitable
	hitable::Hitable
	sin_theta
	cos_theta
	hasbox
	bbox

	function RotateY(h, a)
		sin_theta = sin(deg2rad(a))
		cos_theta = cos(deg2rad(a))
		hasbox, bbox = bounding_box(h, 0, 1)
		minx, miny, minz = Inf, Inf, Inf
		maxx, maxy, maxz = -Inf, -Inf, -Inf
		for i in 0:1, j in 0:1, k in 0:1
			x = i * bbox.max[1] + (1-i) * bbox.min[1]
			y = j * bbox.max[2] + (1-j) * bbox.min[2]
			z = k * bbox.max[3] + (1-k) * bbox.min[3]

			newx =  cos_theta * x + sin_theta * z
			newz = -sin_theta * x + cos_theta * z

			minx = min(newx, minx)
			maxx = max(newx, minx)
			miny = min(y, miny)
			maxy = max(y, miny)
			minz = min(newz, minz)
			maxz = max(newz, minz)
		end

		new(h, sin_theta, cos_theta, hasbox, AaBb(Point3(minx, miny, minz), Point3(maxx, maxy, maxz)))
	end
end

bounding_box(r::RotateY, time0, time1) = r.hasbox, r.bbox

function trace!(rec::Hit, roty::RotateY, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	c,s = roty.cos_theta, roty.sin_theta
	rot(pv, T)   = T(c * pv[1] - s * pv[3], pv[2],  s * pv[1] + c * pv[3])
	unrot(pv, T) = T(c * pv[1] + s * pv[3], pv[2], -s * pv[1] + c * pv[3])

	o = ray.origin
	d = ray.direction
	set_ray!(ray, rot(ray.origin, Point3), rot(ray.direction, Vec3), ray.time)
	if !trace!(rec, roty.hitable, ray, t_min, t_max)
		set_ray!(ray, o, d, ray.time)
		return false
	end

	rec.p = unrot(rec.p, Point3)
	set_face_normal!(rec, ray, unrot(rec.normal, Vec3))
	set_ray!(ray, o, d, ray.time)
	true
end

struct Translate <: Hitable
	hitable::Hitable
	offset
end

function trace!(rec::Hit, t::Translate, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	o = ray.origin
	set_ray!(ray, ray.origin - t.offset, ray.direction, ray.time)
	if !trace!(rec, t.hitable, ray, t_min, t_max)
		set_ray!(ray, o, ray.direction, ray.time)
		return false
	end

	rec.p += t.offset
	set_face_normal!(rec, ray, rec.normal)
	set_ray!(ray, o, ray.direction, ray.time)
	true
end

function bounding_box(t::Translate, time0, time1)
	f, bbox = bounding_box(t.hitable, time0, time1)
	if !f
		return false, bbox
	end

	true, AaBb(bbox.min + t.offset, bbox.max + t.offset)
end


struct ConstantMedium <: Hitable
	boundary::Hitable
	phase_function::Material
	neg_inv_density::Float64
	ConstantMedium(b, d, material) = new(b, material, -1/d)
end

bounding_box(cm::ConstantMedium, time0, time1) = bounding_box(cm.boundary)

function trace!(rec::Hit, cm::ConstantMedium, ray::Ray, t_min::Float64, t_max::Float64)::Bool
	rec1 = Hit()
	if !trace!(rec1, cm.boundary, ray, -Inf, Inf)
		return false
	end

	rec2 = Hit()
	if !trace!(rec2, cm.boundary, ray, rec1.t+0.0001, Inf)
		return false
	end

	rec1.t = max(rec1.t, t_min)
	rec2.t = min(rec2.t, t_max)

	if rec1.t >= rec2.t
		return false
	end

	rec1.t = max(0, rec1.t)

	ray_length = magnitude(ray.direction)
	distance_inside_boundary = (rec2.t - rec1.t) * ray_length
	hit_distance = cm.neg_inv_density * log(rand())

	rec.t = rec1.t + hit_distance / ray_length
	rec.p = at(ray, rec.t)

	rec.normal = Vec3(1,0,0)
	rec.front_face = true
	rec.material = cm.phase_function

	true
end
