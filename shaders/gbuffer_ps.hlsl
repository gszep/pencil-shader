struct gbuffer
{
	float4 screen_position : SV_POSITION;
	float4 world_position : COLOR;
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
	output.normal = input.normal;
    output.depth = input.depth;
	return output;
}