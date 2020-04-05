shader_type particles;

uniform vec3 target_velocity = vec3(0, 0, 0);
uniform float radius = 1.0;

const float TAU = 6.28318530717958647692528676655900576839433879875021;

float rand_from_seed(in uint seed) {
  int k;
  int s = int(seed);
  if (s == 0)
    s = 305420679;
  k = s / 127773;
  s = 16807 * (s - k * 127773) - 2836 * k;
  if (s < 0)
    s += 2147483647;
  seed = uint(s);
  return float(seed % uint(65536)) / 65535.0;
}
uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}

void vertex() {
  if (RESTART) {
	uint alt_seed = hash(NUMBER + RANDOM_SEED);
	vec3 position = vec3(cos(rand_from_seed(alt_seed) * TAU), 
						 sin(rand_from_seed(alt_seed) * TAU), 
						 0) * radius; 
	TRANSFORM[3].xyz = position;
	VELOCITY = target_velocity;
  } else {
    //per-frame code goes here
  }
}
