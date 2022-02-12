
struct Scene
	camera::Camera
#	background::Color
	hitables::Vector{Hitable}
#	materials::Vector{Material}
#	Scene(cam, color) = new(cam, color, Vector{Hitable}(), Vector{Material}())
	Scene(cam) = new(cam, Vector{Hitable}())
end


add!(r::Render, h::Hitable) = add!(r.scene, h)
add!(s::Scene, h::Hitable) = push!(s.hitables, h)
#add!(s::Scene, m::Material) = begin push!(s.materials, m); length(s.materials); end

function trace!(scene::Scene, ray, rec, t_min, t_max)
        hit = false
        for hitable in scene.hitables
                if trace!(hitable, ray, rec, t_min, t_max)
                        hit = true
                end
        end
        hit
end

