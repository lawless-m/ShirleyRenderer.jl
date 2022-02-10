
export Lambertian, Metal, Dielectric, DiffuseLight, Isotropic

reflect(v, n) =  v - 2dot(v,n)*n
function refract(uv, n, etai_over_etat) 
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp = etai_over_etat * (uv + cos_theta*n)
    r_out_parallel = -sqrt(abs(1.0 - magnitude²(r_out_perp))) * n
    r_out_perp + r_out_parallel
end
function reflectance(cosine, ratio)
	r = ((1-ratio) / (1+ratio))^2
	r + (1-r)*(1 - cosine)^5
end
#==
struct Material
	type::MaterialType
	albedo::Color
	texture::Texture
	fuzz::Float64
	ir::Float64
end
==#

Lambertian(t::Texture) = Material(_Lambertian, zero(Color), t, 0, 0)
Lambertian(c::Color) = Lambertian(SolidColor(c))
Lambertian() = Lambertian(Color())

Metal(c::Color, fuzz::Float64) = Material(_Metal, c, Texture(), fuzz, 0)

Dielectric(ir::Float64) = Material(_Dielectric, zero(Color), Texture(), 0, ir)

DiffuseLight(t::Texture) = Material(_DiffuseLight, zero(Color), t, 0, 0)
DiffuseLight(c::Color) = DiffuseLight(SolidColor(c))

Isotropic(t::Texture) = Material(_Isotropic, zero(Color), t, 0, 0)
Isotropic(c::Color) = Isotropic(SolidColor(c))

function scatter!(material, ray, rec)::Tuple{Bool, Color}

	if material.type == _Lambertian
		direction = rec.normal + random_unit_vector()
		if near_zero(direction)
			direction = rec.normal
		end
		set_ray!(ray, rec.p, direction, rec.t)
		return true, value(material.texture, rec.u, rec.v, rec.p)
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

	if material.type == _Isotropic
		set_ray!(ray, rec.p, random_in_unit_sphere(), rec.t)
    	return true, value(material.texture, rec.u, rec.v, rec.p)
	end
	
	# _DiffuseLight
	false, zero(Color)
end


function emitted(material::Material, u::Float64, v::Float64, p::Point3)::Color
	
	if material.type == _DiffuseLight
		return value(material.texture, u, v, p)
	end

	return zero(Color)
end

