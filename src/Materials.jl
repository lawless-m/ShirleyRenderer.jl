
export Lambertian, Metal, Dielectric

reflect(v, n) =  v - 2dot(v,n)*n

struct Lambertian <: Material
	albedo::Color
	Lambertian(c::Color) = new(c)
	Lambertian(r,g,b) = new(Color(r,g,b))
	Lambertian() = Lambertian(Color(rand()*rand(), rand()*rand(), rand()*rand()))
end

function scatter(l::Lambertian, ray::Ray, rec::Hit)
	scatter_direction = rec.normal + random_unit_vector()
	if near_zero(scatter_direction)
		scatter_direction = rec.normal
	end
	Ray(rec.p, scatter_direction), l.albedo
end

struct Metal <: Material
	albedo::Color
	fuzz::Float64
	Metal(a, f) = new(a, f)
	Metal(r,g,b,f) = Metal(Color(r,g,b), f)
end

function scatter(m::Metal, ray::Ray, rec::Hit)
	reflected = reflect(ray.udirection, rec.normal)
	scattered = Ray(rec.p, reflected + m.fuzz * random_in_unit_sphere())
	dot(scattered.direction, rec.normal) > 0 ? (scattered, m.albedo) : (Ray(), zero(Color))
end

struct Dielectric <: Material
	ir::Float64
end

function scatter(d::Dielectric, ray::Ray, rec::Hit) 

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

	Ray(rec.p, direction), Color(1,1,1)
end


