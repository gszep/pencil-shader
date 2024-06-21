cbuffer variables : register(b0)
{
	float2 viewport_size;
};

struct screen
{
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD;
};

Texture2D normals : register(t0);
SamplerState state : register(s0);

struct render_targets
{
	float4 edges : SV_TARGET0;
};

static const float2 delta = 5.0 / viewport_size;
static const float2 du = float2(delta.x, 0);
static const float2 dv = float2(0, delta.y);

float is_edge(float2 uv)
{
	float edge_u = dot(normals.Sample(state, uv + du).xyz, normals.Sample(state, uv - du).xyz);
	float edge_v = dot(normals.Sample(state, uv + dv).xyz, normals.Sample(state, uv - dv).xyz);

	return edge_u < 0.5 || edge_v < 0.5;
}

render_targets main(screen input)
{
	render_targets output;
	input.uv.y = 1 - input.uv.y;

	output.edges = is_edge(input.uv);
	return output;
}