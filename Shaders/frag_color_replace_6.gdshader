shader_type canvas_item;

uniform vec4 from_color_1 : hint_color = vec4(1,1,1,1);
uniform vec4 to_color_1 : hint_color = vec4(1,1,1,1);
uniform vec4 from_color_2 : hint_color = vec4(1,1,1,1);
uniform vec4 to_color_2 : hint_color = vec4(1,1,1,1);
uniform vec4 from_color_3 : hint_color = vec4(1,1,1,1);
uniform vec4 to_color_3 : hint_color = vec4(1,1,1,1);
uniform vec4 from_color_4 : hint_color = vec4(1,1,1,1);
uniform vec4 to_color_4 : hint_color = vec4(1,1,1,1);
uniform vec4 from_color_5 : hint_color = vec4(1,1,1,1);
uniform vec4 to_color_5 : hint_color = vec4(1,1,1,1);
uniform vec4 from_color_6 : hint_color = vec4(1,1,1,1);
uniform vec4 to_color_6 : hint_color = vec4(1,1,1,1);


vec4 swap_color(vec4 c){
	if (distance(c, from_color_1) < 0.05){
		return to_color_1;
	} else if (distance(c, from_color_2) < 0.05){
		return to_color_2;
	} else if (distance(c, from_color_3) < 0.05){
		return to_color_3;
	} else if (distance(c, from_color_4) < 0.05){
		return to_color_4;
	} else if (distance(c, from_color_5) < 0.05){
		return to_color_5;
	} else if (distance(c, from_color_6) < 0.05){
		return to_color_6;
	}
	return c;
}

void fragment(){
	COLOR = swap_color(texture(TEXTURE, UV));
}



