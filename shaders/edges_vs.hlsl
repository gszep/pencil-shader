cbuffer variables : register(b0)
{
	float4x4 orthographic;
	float4x4 geometry_transform;
};

struct vertex
{
	float3 position : POSITION;
	float2 uv : TEXCOORD;
};

struct screen
{
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD;
};

screen main(vertex input)
{
	screen output = (screen)0;

	float4 world_position = geometry_transform * float4(input.position, 1.0);
	output.position = orthographic * world_position;
	output.uv = input.uv;

	return output;
}