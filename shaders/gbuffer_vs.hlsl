cbuffer variables : register(b0)
{
	float4x4 view_projection;
	float4x4 geometry_transform;
	float3 camera_position;
};

struct vertex
{
	float3 position : POSITION;
	float3 normal : NORMAL;
};

struct gbuffer
{
	float4 screen_position : SV_POSITION;
	float4 world_position : COLOR;
	float4 normal : NORMAL;
	float4 depth : COLOR;
};

gbuffer main(vertex input)
{
	gbuffer output = (gbuffer)0;

	output.world_position = geometry_transform * float4(input.position, 1.0);
	output.screen_position = view_projection * output.world_position;

	output.normal = float4(abs(input.normal), 1);
	output.depth = dot(normalize(output.world_position.xyz), normalize(camera_position));

	return output;
}