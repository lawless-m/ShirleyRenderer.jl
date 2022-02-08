
export Lambertian, Metal, Dielectric, DiffuseLight, Isotropic

reflect(v, n) =  v - 2dot(v,n)*n
emitted(m::Material, u::Float64, v::Float64, p::Point3) = Color(0,0,0)
scatter(m::Material, ray::Ray, rec::Hit) = false, zero(Color)

struct Lambertian <: Material
	albedo::Texture
	Lambertian(t::Texture) = new(t)
	Lambertian(c::Color) = Lambertian(SolidColor(c))
end

function scatter!(l::Lambertian, ray::Ray, rec::Hit)
	direction = rec.normal + random_unit_vector()
	if near_zero(direction)
		direction = rec.normal
	end
	set_ray!(ray, rec.p, direction, rec.t)
	true, value(l.albedo, rec.u, rec.v, rec.p)
end

struct Metal <: Material
	albedo::Color
	fuzz::Float64
	Metal(a, f) = new(a, f)
end

function scatter!(m::Metal, ray::Ray, rec::Hit)
	reflected = reflect(ray.udirection, rec.normal)
	direction = reflected + m.fuzz * random_in_unit_sphere()
	if dot(direction, rec.normal) > 0 
		set_ray!(ray, rec.p, direction, rec.t)
		true, m.albedo
	else
		false, zero(Color)
	end
end

struct Dielectric <: Material
	ir::Float64
end

function scatter!(d::Dielectric, ray::Ray, rec::Hit) 

	function reflectance(cosine, ratio)
		r = ((1-ratio) / (1+ratio))^2
		r + (1-r)*(1 - cosine)^5
	end

	refraction_ratio = rec.front_face ? (1.0/d.ir) : d.ir

	cos_theta = min(dot(-ray.udirection, rec.normal), 1.0)
	sin_theta = sqrt(1.0 - cos_theta^2)
	cannot_refract = refraction_ratio * sin_theta > 1.0
	direction = if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand()
			reflect(ray.udirection, rec.normal)
		else
			refract(ray.udirection, rec.normal, refraction_ratio)
		end
	set_ray!(ray, rec.p, direction, rec.t)
	true, Color(1,1,1)
end

struct DiffuseLight <: Material
	emit::Texture
	DiffuseLight(t::Texture) = new(t)
	DiffuseLight(c::Color) = DiffuseLight(SolidColor(c))
end

emitted(d::DiffuseLight, u::Float64, v::Float64, p::Point3) = value(d.emit, u, v, p)

struct Isotropic <: Material
	albedo::Texture
	Isotropic(t::Texture) = new(t)
	Isotropic(c::Color) = Isotropic(SolidColor(c))
end

function scatter!(i::Isotropic, ray::Ray, rec::Hit)
	set_ray!(rec.p, random_in_unit_sphere(), rec.time)
    true, value(i.albedo, hit.u, hit.v, hit.p)
end

