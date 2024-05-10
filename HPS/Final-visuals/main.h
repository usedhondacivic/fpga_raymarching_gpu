#pragma once

enum MOOD {
	ANGRY,
	SAD,
	POSITIVE
};

typedef struct {
	enum MOOD mood;
	float energy;
} arg;

void *visual_thread(void *args);