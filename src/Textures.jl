
export Checker, SolidColor, Noise, TextureMap

struct Texture
    type::Textures
    color::Color
    scale::Float64
    odd
    even
    noise::Perlin
    rgb
    Texture() = new(_Zero, zero(Color), 0.)
    Texture(t, c, s, o, e, n, r) = new(t, c, s, o, e, n, r)
end

noRGB() = Array{RGB{N0f8}, 2}(undef, 1,1)

SolidColor(c) = Texture(_SolidColor, c, 0., Texture(), Texture(), Perlin(), noRGB())

Checker(o::Texture, e::Texture) = Texture(_Checker, zero(Color), 0., o, e, Perlin(), noRGB())
Checker(o::Color, e::Color) = Checker(SolidColor(o), SolidColor(e))

Noise(scale::Float64; point_count=256) = Texture(_Noise, zero(Color), scale, Texture(), Texture(), Perlin(point_count), noRGB())
Noise(scale::Int64; point_count=256) = Noise(Float64(scale); point_count)


TextureMap(filename) = Texture(_TextureMap, zero(Color), 0., Texture(), Texture(), Perlin(), load(filename))

function value(t::Texture, u, v, p)::Color
    if t.type == _SolidColor
        return t.color
    end

    if t.type == _Checker
        return sin(10p[1]) * sin(10p[2]) * sin(10p[3]) < 0 ? value(t.odd, u, v, p) : value(t.even, u, v, p)
    end

    if t.type == _Noise
        v = 1 + sin(t.scale*p[3] + 10*turb(t.noise, p))
        return Color(0.5v)
    end

    if t.type == _TextureMap
        h, w = size(t.rgb)
        i = 1 + round(Int, clamp(u, 0, 1) * (w-1))
        j = 1 + round(Int, clamp(v, 0, 1) * (h-1))
        return Color(t.rgb[j,i])
    end

    return zero(Color)
end
