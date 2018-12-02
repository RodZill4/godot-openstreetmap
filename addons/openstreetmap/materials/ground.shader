shader_type spatial;
render_mode cull_disabled;

uniform sampler2D splatmap;
uniform sampler2D grass_albedo;
uniform float grassres = 1.0;
uniform sampler2D road_albedo;
uniform sampler2D road_nm;
uniform float roadres  = 1.0;
uniform sampler2D dirt_albedo;
uniform float dirtres  = 1.0;
uniform sampler2D water_albedo;
uniform float waterres = 1.0;
uniform vec2 water_movement = vec2(0.0, 0.0);

varying vec2 grass_uv;
varying vec2 dirt_uv;
varying vec2 road_uv;
varying vec2 water_uv;

void vertex() {
	dirt_uv = UV*dirtres;
	grass_uv = UV*grassres;
	road_uv = UV*roadres;
	water_uv = UV*waterres+mod(TIME*water_movement, vec2(1.0, 1.0));
}

void fragment() {
	vec3 splat = texture(splatmap, UV).rgb;
	
	float grassval = splat.g;
	float roadval = splat.r;
	float waterval = splat.b;
	float dirtval = max(0.0, 1.0-grassval-roadval-waterval);
	
	vec4 dirtcol = dirtval * texture(dirt_albedo, dirt_uv);
	vec4 grasscol = grassval * texture(grass_albedo, dirt_uv);
	vec4 roadcol = roadval * texture(road_albedo, road_uv);
	vec4 watercol = waterval * texture(water_albedo, water_uv);
	
	vec3 color = (grasscol+roadcol+dirtcol+watercol).rgb;
	vec3 normalmap = (texture(road_nm, road_uv).rgb-vec3(0.5, 0.5, 0.5)) * roadval + vec3(0.0, 0.0, -1.0) * (1.0 - roadval);
	//normalmap = vec3(0.0, 0.0, -0.5);
	
	ALBEDO = color;
	NORMALMAP = 0.5*normalize(normalmap)+vec3(0.5, 0.5, 0.5);
	NORMALMAP_DEPTH = 1.0;
	ROUGHNESS = 1.0-waterval;
	METALLIC = 0.0;
	SPECULAR = 1.0;
}