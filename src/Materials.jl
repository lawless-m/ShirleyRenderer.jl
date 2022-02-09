
export Lambertian, Metal, Dielectric, DiffuseLight, Isotropic

reflect(v, n) =  v - 2dot(v,n)*n
function refract(uv, n, etai_over_etat) 
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp = etai_over_etat * (uv + cos_theta*n)
    r_out_parallel = -sqrt(abs(1.0 - magnitudesq(r_out_perp))) * n
    r_out_perp + r_out_parallel
end
emitted(m::Material, u::Float64, v::Float64, p::Point3) = zero(Color)
scatter!(m::Material, ray::Ray, rec::Hit)::Tuple{Bool, Color} = false, zero(Color)

struct Lambertian <: Material
	albedo::Texture
	Lambertian(t::Texture) = new(t)
	Lambertian(c::Color) = Lambertian(SolidColor(c))
end

function scatter!(l::Lambertian, ray::Ray, rec::Hit)::Tuple{Bool, Color}
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

function scatter!(m::Metal, ray::Ray, rec::Hit)::Tuple{Bool, Color}
	reflected = reflect(normalize(ray.direction), rec.normal)
	direction = reflected + m.fuzz * random_in_unit_sphere()
	if dot(direction, rec.normal) > 0 
		set_ray!(ray, rec.p, direction, rec.t)
		true, m.albedo
	end

	false, zero(Color)
end

struct Dielectric <: Material
	ir::Float64
end

function scatter!(d::Dielectric, ray::Ray, rec::Hit)::Tuple{Bool, Color}

	function reflectance(cosine, ratio)
		r = ((1-ratio) / (1+ratio))^2
		r + (1-r)*(1 - cosine)^5
	end

	refraction_ratio = rec.front_face ? (1.0/d.ir) : d.ir
	udirection = normalize(ray.direction)
	cos_theta = min(dot(-udirection, rec.normal), 1.0)
	sin_theta = sqrt(1.0 - cos_theta^2)
	cannot_refract = refraction_ratio * sin_theta > 1.0
	direction = if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand()
			reflect(udirection, rec.normal)
		else
			refract(udirection, rec.normal, refraction_ratio)
		end
	set_ray!(ray, rec.p, direction, rec.t)
	true, Color(1,1,1)
end

struct DiffuseLight <: Material
	emit::Texture
	DiffuseLight(t::Texture) = new(t)
	DiffuseLight(c::Color) = DiffuseLight(SolidColor(c))
end

emitted(d::DiffuseLight, u::Float64, v::Float64, p::Point3)::Color = value(d.emit, u, v, p)

struct Isotropic <: Material
	albedo::Texture
	Isotropic(t::Texture) = new(t)
	Isotropic(c::Color) = Isotropic(SolidColor(c))
end

function scatter!(i::Isotropic, ray::Ray, rec::Hit)::Tuple{Bool, Color}
	set_ray!(ray, rec.p, random_in_unit_sphere(), rec.t)
    true, value(i.albedo, rec.u, rec.v, rec.p)
end

