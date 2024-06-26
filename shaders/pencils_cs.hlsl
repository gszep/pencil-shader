cbuffer variables : register(b0)
{
	int width;
	int height;
	int num_pencils;
	float pencil_radius;
	float speed;
	float omega;
	float domega;
	float time;
	float delta;
};

struct Pencil
{
	float2 position;
	float angle;
};

static const float2 d = 1 / float2(width, height);
static const float2 du = float2(d.x, 0);
static const float2 dv = float2(0, d.y);

RWStructuredBuffer<Pencil> pencils : register(u0);
RWTexture2D<float4> traces : register(u1);

SamplerState sampling_state : register(s0);
Texture2D edges : register(t0);
Texture2D normals : register(t1);
Texture2D depth : register(t2);

// Hash function www.cs.ubc.ca/~rbridson/docs/schechter-sca08-turbulence.pdf
uint hash(uint state)
{
	state ^= 2747636419u;
	state *= 2654435769u;
	state ^= state >> 16;
	state *= 2654435769u;
	state ^= state >> 16;
	state *= 2654435769u;
	return state;
}

float random_uniform(uint state)
{
	return state / 4294967295.0;
}

float follow(Pencil pencil, Texture2D signal, float4 color = float4(0.33, 0.33, 0.33, 0))
{
	float2 uv = d * pencil.position;

	float gradient = 0;
	for (float angle = 0.0; angle <= 0.785; angle += 0.1)
	{
		for (int r = 1; r <= 5; r++)
		{
			float4 left_sample = signal.Sample(sampling_state, uv + r * float2(cos(pencil.angle + angle), sin(pencil.angle + angle)) * d);
			float4 right_sample = signal.Sample(sampling_state, uv + r * float2(cos(pencil.angle - angle), sin(pencil.angle - angle)) * d);
			gradient += dot(left_sample, color);
			gradient -= dot(right_sample, color);
		}
	}

	return gradient;
}

Pencil move(Pencil pencil, uint state)
{

	float random = 2 * random_uniform(state) - 1;
	float turn_angle = follow(pencil, edges);
	pencil.angle += turn_angle * delta;
	pencil.angle += omega * random * delta;

	float2 velocity = float2(cos(pencil.angle), sin(pencil.angle));
	pencil.position += speed * velocity * delta;

	return pencil;
}

float gauss(float sigma, int x, int y)
{
	return exp(-(x * x + y * y) / (2 * sigma * sigma));
};

float gaussian_blur(Texture2D tex, float2 uv, float sigma = 5.0)
{
	float blurred_value = 0;
	float normalisation = 0;

	for (int i = -10; i <= 10; i++)
	{
		for (int j = -10; j <= 10; j++)
		{
			float weight = gauss(sigma, i, j);
			float4 color = tex.Sample(sampling_state, uv + float2(i, j) * d);

			blurred_value += any(color) * weight;
			normalisation += weight;
		}
	}
	return blurred_value / normalisation;
};

void draw(Pencil pencil)
{
	float4 color = gaussian_blur(normals, pencil.position * d);

	for (int y = max(0, int(pencil.position.y - pencil_radius)); y < min(height, int(pencil.position.y + pencil_radius)); y++)
	{
		for (int x = max(0, int(pencil.position.x - pencil_radius)); x < min(width, int(pencil.position.x + pencil_radius)); x++)
		{
			float2 p = float2(x, y);
			if (length(p - pencil.position) < pencil_radius)
			{
				float2 uv = p / float2(width, height);
				traces[p] = color;
			}
		}
	}
}

[numthreads(64, 1, 1)] void main(uint3 id : SV_DispatchThreadID)
{
	if (id.x >= num_pencils)
	{
		return; // out of bounds
	}
	Pencil pencil = pencils[id.x];
	uint state = hash(pencil.position.y * width + pencil.position.x + hash(id.x + time * 100000));

	pencil = move(pencil, state);
	pencil.position %= float2(width, height); // periodic boundary conditions

	pencils[id.x] = pencil;
	draw(pencil);
}