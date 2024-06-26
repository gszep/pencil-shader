struct gbuffer
{
	float4 position : SV_POSITION;
	float4 normal : NORMAL;
	float4 depth : COLOR;
};

struct render_targets
{
	float4 normal : SV_TARGET0;
	float4 depth : SV_TARGET1;
};

render_targets main(gbuffer input)
{
	render_targets output;

	output.normal = float4(input.normal.xyz, 1);
	output.depth = input.depth;
	return output;
}