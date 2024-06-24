cbuffer variables : register(b0)
{
	int width;
	int height;
	float delta;
	float evaporation;
};

RWTexture2D<float4> traces : register(u0);

[numthreads(8, 8, 1)] void main(uint3 id : SV_DispatchThreadID)
{
	if (id.x >= width || id.y >= height)
	{
		return;
	}
	float4 trace = max(0, traces[id.xy] - evaporation * delta);
	traces[id.xy] = trace;
}