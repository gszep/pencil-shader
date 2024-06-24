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

float4 gradient(Texture2D<float4> E, float2 uv, float2 direction)
{
	float4 dEu = E.Sample(sampling_state, uv + du) - E.Sample(sampling_state, uv - du);
	float4 dEv = E.Sample(sampling_state, uv + dv) - E.Sample(sampling_state, uv - dv);
	return dEu * direction[0] + dEv * direction[1];
}

Pencil move(Pencil pencil, uint state)
{

	float2 uv = d * pencil.position;
	float random = random_uniform(state) * 2 - 1;

	// float dF = gradient(edges, uv, float2(cos(pencil.angle + domega), sin(pencil.angle + domega))) - gradient(edges, uv, float2(cos(pencil.angle - domega), sin(pencil.angle - domega)));
	// pencil.angle += dF.x * delta;

	float2 velocity = float2(cos(pencil.angle), sin(pencil.angle));
	pencil.position += speed * velocity * delta;
	pencil.angle += omega * random * delta;

	//  float sensorAngle = agent.angle + sensorAngleOffset;
	//  float2 sensorDir = float2(cos(sensorAngle), sin(sensorAngle));

	// float2 sensorPos = agent.position + sensorDir * settings.sensorOffsetDst;
	// int sensorCentreX = (int)sensorPos.x;
	// int sensorCentreY = (int)sensorPos.y;

	// float sum = 0;

	// int4 senseWeight = agent.speciesMask * 2 - 1;

	// for (int offsetX = -settings.sensorSize; offsetX <= settings.sensorSize; offsetX++)
	// {
	// 	for (int offsetY = -settings.sensorSize; offsetY <= settings.sensorSize; offsetY++)
	// 	{
	// 		int sampleX = min(width - 1, max(0, sensorCentreX + offsetX));
	// 		int sampleY = min(height - 1, max(0, sensorCentreY + offsetY));
	// 		sum += dot(senseWeight, TrailMap[int2(sampleX, sampleY)]);
	// 	}
	// }

	// return sum;
	return pencil;
}

void draw(Pencil pencil)
{
	for (int y = max(0, int(pencil.position.y - pencil_radius)); y < min(height, int(pencil.position.y + pencil_radius)); y++)
	{
		for (int x = max(0, int(pencil.position.x - pencil_radius)); x < min(width, int(pencil.position.x + pencil_radius)); x++)
		{
			float2 p = float2(x, y);
			if (length(p - pencil.position) < pencil_radius)
			{
				float2 uv = p / float2(width, height);
				float4 color = length(gradient(edges, uv, float2(1, 1)));

				color.a = 1;
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