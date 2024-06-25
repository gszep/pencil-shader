cbuffer variables : register(b0)
{
	float2 viewport_size;
	float edge_thickness;
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

static const float2 d = 1 / viewport_size;
static const float2 du = float2(d.x, 0);
static const float2 dv = float2(0, d.y);

float4 edge(Texture2D<float4> tex, float2 uv)
{
	float4 dTu = tex.Sample(state, uv + edge_thickness * du) - tex.Sample(state, uv - edge_thickness * du);
	float4 dTv = tex.Sample(state, uv + edge_thickness * dv) - tex.Sample(state, uv - edge_thickness * dv);
	return sqrt(dot(dTu, dTu) + dot(dTv, dTv));
};

render_targets main(screen input)
{
	render_targets output;
	input.uv.y = 1 - input.uv.y;

	output.edges = edge(normals, input.uv);
	return output;
}