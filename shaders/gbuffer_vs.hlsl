cbuffer variables : register(b0)
{
	float4x4 view;
	float4x4 projection;
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
	float4 position : SV_POSITION;
	float4 normal : NORMAL;
	float4 depth : COLOR;
};

gbuffer main(vertex input)
{
	gbuffer output = (gbuffer)0;

	float4x4 rotate = float4x4(
		cos(time), 0, sin(time), 0,
		0, 1, 0, 0,
		-sin(time), 0, cos(time), 0,
		0, 0, 0, 1);

	float4 world_position = rotate * geometry_transform * float4(input.position, 1.0);
	output.normal = rotate * geometry_transform * float4(input.normal, 0.0);

	float4 view_position = view * world_position;
	output.position = projection * view_position;

	output.normal = view * output.normal;
	output.depth = dot(normalize(world_position.xyz), normalize(camera_position));

	return output;
}