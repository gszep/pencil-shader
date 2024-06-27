cbuffer variables : register(b0)
{
	int width;
	int height;
	float delta;
	float2 viewport_size;
	float evaporation;
};

static const float2 d = 1 / float2(width, height);

RWTexture2D<float4> traces : register(u0);
Texture2D normals : register(t0);
Texture2D edges : register(t1);
SamplerState state : register(s0);

[numthreads(8, 8, 1)] void main(uint3 id : SV_DispatchThreadID)
{
	if (id.x >= width || id.y >= height)
	{
		return;
	}

	bool foreground = any(normals.Sample(state, id.xy * d));
	float rate = foreground ? evaporation : 5 * evaporation;

	float4 trace = max(0, traces[id.xy] - rate * delta);
	traces[id.xy] = trace;
}