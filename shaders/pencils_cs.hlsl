cbuffer variables : register(b0)
{
	uint width;
	uint height;
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
	float2 position = pencils[id.x].position;
	float2 velocity = pencils[id.x].velocity;

	position += velocity * delta;

	// Bounce off the walls
	if (position.y < 0 || position.y > height)
	{
		velocity.y *= -1.0;
		//position.y = clamp(position.y, 0, height);
	}

	pencils[id.x].position = position;
	pencils[id.x].velocity = velocity;
	traces[position] = float4(1, 1, 1, 1);
}