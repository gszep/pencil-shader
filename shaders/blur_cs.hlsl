cbuffer variables : register(b0)
{
	float2 viewport_size;
};

static const float2 d = 1 / viewport_size;
static const float2 du = float2(d.x, 0);
static const float2 dv = float2(0, d.y);

RWTexture2D<float4> tex : register(u0);
SamplerState state : register(s0);

float gauss(float sigma, int x, int y)
{
	return exp(-(x * x + y * y) / (2 * sigma * sigma));
};

float4 gaussian_blur(Texture2D tex, float2 uv, float sigma = 5.0)
{
	float4 color = 0;
	float normalisation = 0;

	for (int i = -10; i <= 10; i++)
	{
		for (int j = -10; j <= 10; j++)
		{
			float weight = gauss(sigma, i, j);
			color += tex.Sample(state, uv + float2(i, j) * d) * weight;
			normalisation += weight;
		}
	}
	return color / normalisation;
};

[numthreads(8, 8, 1)] void main(uint3 id : SV_DispatchThreadID)
{
	if (id.x >= viewport_size.x || id.y >= viewport_size.y)
	{
		return; // out of bounds
	}
	tex[id.xy] = gaussian_blur(tex, id.xy * d);
}