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

float is_edge(float2 uv)
{
	float3 normal = normals.Sample(state, uv).xyz;
	float3 normal_x = normals.Sample(state, uv + float2(0.01, 0)).xyz;
	float3 normal_y = normals.Sample(state, uv + float2(0, 0.01)).xyz;

	float3 edge_x = abs(normal - normal_x);
	float3 edge_y = abs(normal - normal_y);

	float3 edge = edge_x + edge_y;
	float3 edge_threshold = 0.01;

	float3 edge_result = step(edge_threshold, edge);

	return dot(edge_result, float3(1, 1, 1)) / 3;
}

render_targets main(screen input)
{
	render_targets output;
	input.uv.y = 1 - input.uv.y;

	output.edges = is_edge(input.uv);
	return output;
}