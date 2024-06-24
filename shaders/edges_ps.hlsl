cbuffer variables : register(b0)
{
	float2 viewport_size;
	float edge_thickness;
	float edge_threshold;
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

	return edge_u < edge_threshold || edge_v < edge_threshold;
};

float gauss(float sigma, int x, int y)
{
	return exp(-(x * x + y * y) / (2 * sigma * sigma));
};

float4 gaussian_blur(Texture2D tex, float2 uv, float sigma = 5.0)
{
	float4 color = 0;
	float normalisation = 0;

	for (int i = -7; i <= 7; i++)
	{
		for (int j = -7; j <= 7; j++)
		{
			float weight = gauss(sigma, i, j);
			color += tex.Sample(state, uv + float2(i, j) * d) * weight;
			normalisation += weight;
		}
	}
	return color / normalisation;
};

render_targets main(screen input)
{
	render_targets output;
	input.uv.y = 1 - input.uv.y;

	output.edges = gaussian_blur(normals, input.uv);
	return output;
}