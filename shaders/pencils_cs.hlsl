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
	// respawn background pencils
	if (gaussian_blur(normals, pencil.position * d) < random_uniform(state))
	{
		state = hash(state);

		float x = random_uniform(state) * width;
		state = hash(state);
		float y = random_uniform(state) * height;
		state = hash(state);

		pencil.position = float2(x, y);
	}

	float speed_factor = 1;
	float2 uv = pencil.position * d;

	float4 normal = normals.Sample(sampling_state, uv);
	float4 edge = edges.Sample(sampling_state, uv);

	if (normal.a > 0 && !any(edge > 0.5))
	{
		pencil.angle = atan2(normal.y, -normal.x);
		speed_factor = 2;
	}

	// follow edges
	float turn_angle = follow(pencil, edges);
	pencil.angle += turn_angle * delta;

	// angular noise
	pencil.angle += omega * (2 * random_uniform(state) - 1) * delta;
	state = hash(state);

	// update position
	float2 velocity = speed_factor * float2(cos(pencil.angle), sin(pencil.angle));
	pencil.position += speed * velocity * delta;

	return pencil;
}

void draw(Pencil pencil)
{
	float4 color = gaussian_blur(normals, pencil.position * d);
	float strength = pencil_radius * max(1, 4 * log(depth.Sample(sampling_state, pencil.position * d).r + 1));

	for (int y = max(0, int(pencil.position.y - strength)); y < min(height, int(pencil.position.y + strength)); y++)
	{
		for (int x = max(0, int(pencil.position.x - strength)); x < min(width, int(pencil.position.x + strength)); x++)
		{
			float2 p = float2(x, y);
			if (length(p - pencil.position) < strength)
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