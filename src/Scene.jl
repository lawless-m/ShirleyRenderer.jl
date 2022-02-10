
struct Scene
	camera::Camera
	background::Color
	hitables::Vector{Hitable}
	materials::Vector{Material}
	Scene(cam, color) = new(cam, color, Vector{Hitable}(), Vector{Material}())
end

add!(s::Scene, h::Hitable) = push!(s.hitables, h)
add!(s::Scene, m::Material) = begin push!(s.materials, m); length(s.materials); end
