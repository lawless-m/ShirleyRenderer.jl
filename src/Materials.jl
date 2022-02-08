
export Lambertian, Metal, Dielectric, DiffuseLight, Isotropic

reflect(v, n) =  v - 2dot(v,n)*n
emitted(m::Material, u::Float64, v::Float64, p::Point3) = Color(0,0,0)
scatter(m::Material, ray::Ray, hit::Hit) = Ray(), zero(Color)

struct Lambertian <: Material
	albedo::Texture
	Lambertian(t::Texture) = new(t)
	Lambertian(c::Color) = Lambertian(SolidColor(c))
end

function scatter(l::Lambertian, ray::Ray, hit::Hit)
	scatter_direction = hit.normal + random_unit_vector()
	if near_zero(scatter_direction)
		scatter_direction = hit.normal
	end
	Ray(hit.p, scatter_direction), value(l.albedo, hit.u, hit.v, hit.p)
end

struct Metal <: Material
	albedo::Color
	fuzz::Float64
	Metal(a, f) = new(a, f)
end

function scatter(m::Metal, ray::Ray, hit::Hit)
	reflected = reflect(ray.udirection, hit.normal)
    scattered = Ray(hit.p, reflected + m.fuzz * random_in_unit_sphere())
	dot(scattered.direction, hit.normal) > 0 ? (scattered, m.albedo) : (Ray(), zero(Color))
end

struct Dielectric <: Material
	ir::Float64
end

function scatter(d::Dielectric, ray::Ray, hit::Hit) 

	function reflectance(cosine, ratio)
		r = ((1-ratio) / (1+ratio))^2
		r + (1-r)*(1 - cosine)^5
	end

	refraction_ratio = hit.front_face ? (1.0/d.ir) : d.ir

	cos_theta = min(dot(-ray.udirection, hit.normal), 1.0)
	sin_theta = sqrt(1.0 - cos_theta^2)
	cannot_refract = refraction_ratio * sin_theta > 1.0
	direction = if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand()
			reflect(ray.udirection, hit.normal)
		else
			refract(ray.udirection, hit.normal, refraction_ratio)
		end

	Ray(hit.p, direction), Color(1,1,1)
end

struct DiffuseLight <: Material
	emit::Texture
	DiffuseLight(t::Texture) = new(t)
	DiffuseLight(c::Color) = DiffuseLight(SolidColor(c))
end

emitted(e::DiffuseLight, u::Float64, v::Float64, p::Point3) = value(d.emit, u, v, p)

struct Isotropic <: Material
	albedo::Texture
	Isotropic(t::Texture) = new(t)
	Isotropic(c::Color) = Isotropic(SolidColor(c))
end

function scatter(i::Isotropic, ray::Ray, hit::Hit)
	scattered = Ray(hit.p, random_in_unit_sphere(), ray.time);
    attenuation = value(i.albedo, hit.u, hit.v, hit.p);
end

