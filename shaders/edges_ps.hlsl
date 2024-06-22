cbuffer variables : register(b0)
{
	float2 viewport_size;
	float thickness;
	float threshold;
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

static const float2 delta = thickness / viewport_size;
static const float2 du = float2(delta.x, 0);
static const float2 dv = float2(0, delta.y);

float is_edge(float2 uv)
{

	float4 du1 = normals.Sample(state, uv + du);
	float4 du2 = normals.Sample(state, uv - du);

	float4 dv1 = normals.Sample(state, uv + dv);
	float4 dv2 = normals.Sample(state, uv - dv);

	du1.a = 1;
	du2.a = 1;

	dv1.a = 1;
	dv2.a = 1;

	float edge_u = dot(normalize(du1), normalize(du2));
	float edge_v = dot(normalize(dv1), normalize(dv2));

	return edge_u < threshold || edge_v < threshold;
}

render_targets main(screen input)
{
	render_targets output;
	input.uv.y = 1 - input.uv.y;

	output.edges = is_edge(input.uv);
	return output;
}