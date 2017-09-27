

precision mediump float;
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D tex0; 
uniform float u_rippleDistance;
uniform float u_rippleRange;

float waveHeight(vec2 p)
{
	float ampFactor = 2.0;
	float distFactor = 2.0;
	float dist = length(p);
	float delta = abs(u_rippleDistance - dist);
	if (delta <= u_rippleRange)
	{
		return cos((u_rippleDistance - dist) * distFactor) * (u_rippleRange - delta) * ampFactor;
	}
	
	return 0;
}

void main() 
{
    vec2 p = v_texCoord - vec2(0.5, 0.5);
	
    //offset texcoord along dist direction
	vec2 pos = v_texCoord + normalize(p) * waveHeight(p);
    gl_FragColor = texture2D(tex0, pos) * v_fragmentColor;
}