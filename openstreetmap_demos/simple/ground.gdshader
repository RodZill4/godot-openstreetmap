shader_type spatial;
render_mode blend_mix,depth_draw_opaque,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_metallic : hint_default_white;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_default_white;
uniform vec4 roughness_texture_channel;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

float rand(vec2 x) {
    return fract(sin(dot(x, vec2(13.9898, 8.141))) * 43758.5453);
}

float perlin(vec2 uv, vec2 size, int iterations, float persistence) {
    float rv = 0.0;
    float coef = 1.0;
    float acc = 0.0;
    for (int i = 0; i < iterations; ++i) {
    	vec2 step = vec2(1.0)/size;
        float f0 = rand(floor(fract(uv)*size));
        float f1 = rand(floor(fract(uv+vec2(step.x, 0.0))*size));
        float f2 = rand(floor(fract(uv+vec2(0.0, step.y))*size));
        float f3 = rand(floor(fract(uv+vec2(step.x, step.y))*size));
        vec2 mixval = fract(uv*size);
        mixval = 0.5*(1.0-cos(3.1415928*mixval));
        rv += coef * mix(mix(f0, f1, mixval.x), mix(f2, f3, mixval.x), mixval.y);
        acc += coef;
        size *= 2.0;
        coef *= persistence;
    }

    return rv / acc;
}

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;
	float p = clamp(perlin(base_uv, vec2(4.0), 10, 0.8), 0.0, 1.0);
	ALBEDO = 0.5*vec3(0.3-p, 1.0, p);
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
}
