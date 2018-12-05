shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_detail_albedo : hint_albedo;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

float rand(vec2 x) {
    return fract(cos(dot(x, vec2(13.9898, 8.141))) * 43758.5453);
}

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	UV2=UV2*uv2_scale.xy+uv2_offset.xy;
}

void fragment() {
	float r = rand(floor(vec2(UV.x, UV2.y)));
	vec2 uv = vec2(floor(UV.x)+clamp((fract(UV.x)-(1.0-1.0/UV.y)*0.5)*UV.y, 0.0, 1.0), UV2.y);
	vec2 base_uv = 0.5*(uv + vec2(floor(r*2.0), floor(mod(r*4.0, 2.0))));
	vec2 base_uv2 = UV2;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	vec4 detail = texture(texture_detail_albedo,base_uv2);
	ALBEDO.rgb = mix(detail.rgb,albedo.rgb * albedo_tex.rgb,albedo_tex.a);
}
