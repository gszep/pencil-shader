cbuffer variables : register(b0)
{
	float delta;
};

struct pencil {
	float2 position;
	float2 velocity;
};

RWStructuredBuffer<pencil> pencils : register(u0);

[numthreads(1, 1, 1)]
void main( uint3 id : SV_DispatchThreadID )
{
	float2 position = pencils[id.x].position;
	float2 velocity = pencils[id.x].velocity;
	
	pencils[id.x].position += velocity*delta;
}