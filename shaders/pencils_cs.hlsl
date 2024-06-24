cbuffer variables : register(b0)
{
	int width;
	int height;
	int num_pencils;
	float delta;
};

struct pencil
{
	float2 position;
	float2 velocity;
};

RWStructuredBuffer<pencil> pencils : register(u0);
RWTexture2D<float4> traces : register(u1);

[numthreads(16, 1, 1)] void main(uint3 id : SV_DispatchThreadID)
{
	if (id.x >= num_pencils)
	{
		return;
	}
	float2 position = pencils[id.x].position;
	float2 velocity = pencils[id.x].velocity;

	position += velocity * delta;
	position %= float2(width, height);

	pencils[id.x].position = position;
	pencils[id.x].velocity = velocity;
	traces[position] = float4(1, 1, 1, 1);
}