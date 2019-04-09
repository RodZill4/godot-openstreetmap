shader_type particles;
render_mode keep_data, disable_force, disable_velocity;

uniform float rows = 16;
uniform float spacing = 1.0;
uniform float random = 1.0;
uniform float tile_size = 1.0;
uniform sampler2D splatmap;
uniform vec2 start = vec2(0.0, 0.0);
uniform vec4 condition = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 condition_mask = vec4(1.0, 1.0, 1.0, 0.0);

vec3 rand3(vec2 x) {
    return fract(cos(vec3(dot(x, vec2(13.9898, 8.141)),
                          dot(x, vec2(3.4562, 17.398)),
                          dot(x, vec2(13.254, 5.867)))) * 43758.5453);
}

void vertex() {
	// obtain our position based on which particle we're rendering
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;
	
	// and now apply our spacing
	pos += vec3(start.x, 0.0, start.y);
	pos *= spacing;
	
	// now center on our particle location but within our spacing
	//pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing);
	//pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing);
	
	// now add some noise based on our _world_ position
	vec3 noise = rand3(pos.xz);
	pos.x += (noise.x-0.5) * spacing * random;
	pos.z += (noise.y-0.5) * spacing * random;
	
	// apply our height
	vec4 biome = texture(splatmap, (pos.xz+vec2(0.5, 0.5))/tile_size);
	pos.y = -10.0*dot(abs(biome-condition), condition_mask);
	
	// rotate our transform
	TRANSFORM[0][0] = cos(noise.z * 6.28);
	TRANSFORM[0][2] = -sin(noise.z * 6.28);
	TRANSFORM[2][0] = sin(noise.z * 6.28);
	TRANSFORM[2][2] = cos(noise.z * 6.28);
	
	// update our transform to place
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;
}