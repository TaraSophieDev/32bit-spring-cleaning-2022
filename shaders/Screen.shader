shader_type canvas_item;

uniform int downscale_factor = 3;
//uniform int height_resolution = 1920;
//uniform int downscale_factor clamp(factor, 1, 10);

void fragment() {
	//int downscale_factor = int(textureSize(SCREEN_TEXTURE,0).x/downscale_factor);
	ivec2 uv = ivec2(FRAGCOORD.xy / float(downscale_factor));
	vec4 color = texelFetch(TEXTURE, uv * downscale_factor, 0);
	COLOR = color;
}