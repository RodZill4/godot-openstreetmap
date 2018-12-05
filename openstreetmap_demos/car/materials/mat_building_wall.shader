shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_lambert_wrap,specular_schlick_ggx;

uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_metallic : hint_white;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_white;
uniform vec4 roughness_texture_channel;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_detail_albedo : hint_albedo;
uniform sampler2D texture_detail_normal : hint_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform sampler2D interior_tex;

varying vec3 oI;

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 interior_uv(vec2 uv, vec3 rand) {
	//calculate wall locations
	vec3 walls = step(vec3(0.0), oI);
	
	//how much of the ray is needed to get from the oE to each of the walls
	vec3 noE = vec3(uv, 1.0);
	vec3 rayFractions = (walls - noE) / oI;
	
	//texture-coordinates of intersections
	vec2 intersectionXY = (noE + rayFractions.z * oI).xy;
	vec2 intersectionXZ = (noE + rayFractions.y * oI).xz;
	vec2 intersectionZY = (noE + rayFractions.x * oI).zy;
	
	vec2 floorUV = intersectionXZ+vec2(4.0, floor(rand.x*5.0));
	vec2 ceilingUV = intersectionXZ+vec2(3.0, floor(rand.y*5.0));
	vec2 verticalUV = mix(ceilingUV, floorUV, step(0.0, oI.y));
	vec2 wall1UV = vec2(1.0, mod(floor((rand.z+rand.y)*10.0), 5.0))+vec2(-1.0, 1.0)*intersectionZY;
	vec2 wall2UV = intersectionXY+vec2(1.0, mod(floor((rand.z+rand.x)*5.0), 5.0));
	vec2 wall3UV = intersectionZY+vec2(2.0, floor(rand.z*5.0));
	vec2 horizontalUV = mix(wall1UV, wall3UV, step(0.0, oI.x));
	
	// intersect walls
	float xVSz = step(rayFractions.x, rayFractions.z);
	vec2 iuv = mix(wall2UV, horizontalUV, xVSz);
	float rayFraction_xVSz = mix(rayFractions.z, rayFractions.x, xVSz);
	float xzVSy = step(rayFraction_xVSz, rayFractions.y);
	
	return mix(verticalUV, iuv, xzVSy)/5.0;
}

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	UV2=UV2*uv2_scale.xy+uv2_offset.xy;

	mat4 inv_modelview = inverse(MODELVIEW_MATRIX);
	vec3 oE = inv_modelview[3].xyz;
	oI = VERTEX - oE;
	oI = vec3(dot(TANGENT, oI), -dot(BINORMAL, oI), dot(NORMAL, oI));
}

vec3 rand3(vec2 x) {
    return fract(cos(vec3(dot(x, vec2(13.9898, 8.141)),
                          dot(x, vec2(3.4562, 17.398)),
                          dot(x, vec2(13.254, 5.867)))) * 43758.5453);
}

void fragment() {
	vec2 base_uv = vec2(floor(UV.x)+clamp((fract(UV.x)-(1.0-1.0/UV.y)*0.5)*UV.y, 0.0, 1.0), UV2.y);
	vec2 base_uv2 = UV2;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	NORMALMAP = texture(texture_normal,base_uv).rgb;
	NORMALMAP_DEPTH = normal_scale;
	vec4 detail_tex = texture(texture_detail_albedo,base_uv2);
	vec4 detail_norm_tex = texture(texture_detail_normal,base_uv2);
	vec3 detail = mix(ALBEDO.rgb,detail_tex.rgb,detail_tex.a);
	vec3 detail_norm = mix(NORMALMAP,detail_norm_tex.rgb,detail_tex.a);
	NORMALMAP = mix(NORMALMAP,detail_norm,1.0-albedo_tex.a);
	ALBEDO.rgb = mix(ALBEDO.rgb,detail,1.0-albedo_tex.a);
	vec3 rand = rand3(floor(UV));
	vec4 interior = texture(interior_tex, interior_uv(fract(base_uv), rand)).rgba;
	interior.xyz = mix(hsv_to_rgb(vec3(dot(rand, vec3(2.0)), 0.3, 0.95)), interior.xyz, interior.a);
	EMISSION = 0.5*(1.0-ROUGHNESS)*interior.rgb;
}
