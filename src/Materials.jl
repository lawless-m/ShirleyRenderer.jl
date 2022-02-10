
export Lambertian, Metal, Dielectric

reflect(v, n) =  v - 2dot(v,n)*n

function refract(uv, n, etai_over_etat) 
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp = etai_over_etat * (uv + cos_theta*n)
    r_out_parallel = -sqrt(abs(1.0 - magnitudesq(r_out_perp))) * n
    r_out_perp + r_out_parallel
end

@enum MaterialType _Lambertian _Metal _Dielectric _Isomorphic

struct Material
	type::MaterialType
	albedo::Color
	fuzz::Float64
	ir::Float64
end

Lambertian(c::Color) = Material(_Lambertian, c, 0, 0)
Lambertian() = Material(_Lambertian, Color(rand()*rand(), rand()*rand(), rand()*rand()), 0, 0)
Metal(c, f) = Material(_Metal, c, f, 0)
Dielectric(ir) = Material(_Dielectric, zero(Color), 0, ir)

function scatter!(material, ray, rec)

	if material.type == _Lambertian
		direction = rec.normal + random_unit_vector()
		if near_zero(direction)
			direction = rec.normal
		end
		set_ray!(ray, rec.p, direction, rec.t)
		return true, material.albedo
	end

	if material.type == _Metal
		reflected = reflect(unit(ray.direction), rec.normal)
		direction = reflected + material.fuzz * random_in_unit_sphere()
		if dot(direction, rec.normal) > 0 
			set_ray!(ray, rec.p, direction, rec.t)
			return true, material.albedo
		else
			return false, zero(Color)
		end
	end

	if material.type == _Dielectric

		function reflectance(cosine, ratio)
			r = ((1-ratio) / (1+ratio))^2
			r + (1-r)*(1 - cosine)^5
		end

		refraction_ratio = rec.front_face ? (1.0/material.ir) : material.ir

		udirection = unit(ray.direction)

		cos_theta = min(dot(-udirection, rec.normal), 1.0)
		sin_theta = sqrt(1.0 - cos_theta^2)
		cannot_refract = refraction_ratio * sin_theta > 1.0
		direction = if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand()
				reflect(udirection, rec.normal)
			else
				refract(udirection, rec.normal, refraction_ratio)
			end
		set_ray!(ray, rec.p, direction, rec.t)
		return true, Color(1,1,1)
	end

	# should never come here but helps with type stability
	false, zero(Color)
end


