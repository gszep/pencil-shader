cbuffer variables : register(b0)
{
	int width;
	int height;
	float delta;
};

struct pencil
{
	float2 position;
	float2 velocity;
};

RWStructuredBuffer<pencil> pencils : register(u0);
RWTexture2D<float4> traces : register(u1);

[numthreads(16, 1, 1)] void main(uint3 dispatchThreadID : SV_DispatchThreadID, uint3 groupThreadID : SV_GroupThreadID, uint3 groupID : SV_GroupID)
{
	float2 position = pencils[dispatchThreadID.x].position;
	float2 velocity = pencils[dispatchThreadID.x].velocity;

	position += velocity * delta;
	position %= float2(width, height);

	pencils[dispatchThreadID.x].position = position;
	pencils[dispatchThreadID.x].velocity = velocity;
	traces[position] = float4(1, 1, 1, 1);
}