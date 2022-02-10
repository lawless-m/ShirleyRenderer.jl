
export Checker, SolidColor, Noise, TextureMap

struct Texture
    type::Textures
    color::Color
    scale::Float64
    odd::Int64
    even::Int64
    noise::Perlin
    rgb
end

noRGB() = Array{RGB{N0f8}, 2}(undef, 1,1)

SolidColor(c) = Texture(_SolidColor, c, 0., 0, 0, Perlin(), noRGB())

Checker(o::Int64, e::Int64) = Texture(_Checker, zero(Color), 0., o, e, Perlin(), noRGB())

Noise(scale::Float64; point_count=256) = Texture(_Noise, zero(Color), scale, 0, 0, Perlin(point_count), noRGB())
Noise(scale::Int64; point_count=256) = Noise(Float64(scale); point_count)

TextureMap(filename) = Texture(_TextureMap, zero(Color), 0., 0, 0, Perlin(), load(filename))

function value(scene, tex::Int64, u, v, p)::Color

	texture = scene.textures[tex]

    if texture.type == _SolidColor
        return texture.color
    end

    if texture.type == _Checker
        return sin(10p[1]) * sin(10p[2]) * sin(10p[3]) < 0 ? value(scene, texture.odd, u, v, p) : value(scene, texture.even, u, v, p)
    end

    if scene.textures[tex].type == _Noise
        v = 1 + sin(texture.scale*p[3] + 10*turb(texture.noise, p))
        return Color(0.5v)
    end

    if texture.type == _TextureMap
        h, w = size(texture.rgb)
        i = 1 + round(Int, clamp(u, 0, 1) * (w-1))
        j = 1 + round(Int, clamp(v, 0, 1) * (h-1))
        return Color(texture.rgb[j,i])
    end

    return zero(Color)
end

