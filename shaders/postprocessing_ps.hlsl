struct screen
{
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD;
};

Texture2D normals : register(t0);
Texture2D depth : register(t1);
Texture2D edges : register(t2);
SamplerState state : register(s0);

struct render_targets
{
	float4 viewport : SV_TARGET0;
};


render_targets main(screen input)
{
	render_targets output = (render_targets) 0;
	input.uv.y = 1 - input.uv.y;

	output.viewport += normals.Sample(state,input.uv);
	output.viewport += depth.Sample(state,input.uv);
	output.viewport += edges.Sample(state,input.uv);
	
	return output;
}