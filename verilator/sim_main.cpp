#include "Vtop.h"
#include <SDL.h>
#include <stdio.h>
#include <verilated.h>

// screen dimensions
const int H_RES = 640;
const int V_RES = 480;

typedef struct Pixel
{			   // for SDL texture
	uint8_t a; // transparency
	uint8_t b; // blue
	uint8_t g; // green
	uint8_t r; // red
} Pixel;

int main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);

	const std::unique_ptr<VerilatedContext> contextp{ new VerilatedContext };

	// Verilator must compute traced signals
	contextp->traceEverOn(true);
	// This needs to be called before you create any model
	contextp->commandArgs(argc, argv);

	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		printf("SDL init failed.\n");
		return 1;
	}

	Pixel screenbuffer[H_RES * V_RES];

	SDL_Window *sdl_window = NULL;
	SDL_Renderer *sdl_renderer = NULL;
	SDL_Texture *sdl_texture = NULL;

	sdl_window = SDL_CreateWindow("raymarcher",
								  SDL_WINDOWPOS_CENTERED,
								  SDL_WINDOWPOS_CENTERED,
								  H_RES,
								  V_RES,
								  SDL_WINDOW_SHOWN);
	if (!sdl_window) {
		printf("Window creation failed: %s\n", SDL_GetError());
		return 1;
	}

	sdl_renderer = SDL_CreateRenderer(
	  sdl_window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
	if (!sdl_renderer) {
		printf("Renderer creation failed: %s\n", SDL_GetError());
		return 1;
	}

	sdl_texture = SDL_CreateTexture(sdl_renderer,
									SDL_PIXELFORMAT_RGBA8888,
									SDL_TEXTUREACCESS_TARGET,
									H_RES,
									V_RES);
	if (!sdl_texture) {
		printf("Texture creation failed: %s\n", SDL_GetError());
		return 1;
	}

	// reference SDL keyboard state array:
	// https://wiki.libsdl.org/SDL_GetKeyboardState
	const Uint8 *keyb_state = SDL_GetKeyboardState(NULL);

	printf("Simulation running. Press 'Q' in simulation window to quit.\n\n");

	// initialize Verilog module
	Vtop *top = new Vtop;

	// reset
	top->sim_rst = 1;
	top->clk_pix = 0;
	top->clk_50 = 0;
	top->eval_step();
	top->clk_pix = 1;
	top->clk_50 = 1;
	top->eval_step();
	top->sim_rst = 0;
	top->clk_pix = 0;
	top->clk_50 = 0;
	top->eval_step();
	top->eval_end_step();

	// initialize frame rate
	uint64_t start_ticks = SDL_GetPerformanceCounter();
	uint64_t frame_count = 0;

	// main loop
	while (1) {
		// cycle the clock
		// VGA @ 25 MHz, clock_50 @ 50 MHz
		contextp->timeInc(1);
		top->clk_50 = !top->clk_50;
		if (top->clk_50) {
			top->clk_pix = !top->clk_pix;
		}

		// check for quit event
		SDL_Event e;
		if (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				break;
			}
		}

		if (keyb_state[SDL_SCANCODE_Q])
			break; // quit if user presses 'Q'

		// update pixel if not in blanking interval
		if (top->sdl_de) {
			Pixel *p = &screenbuffer[top->sdl_sy * H_RES + top->sdl_sx];
			p->a = 0xFF; // transparency
			p->b = top->sdl_b;
			p->g = top->sdl_g;
			p->r = top->sdl_r;
		}

		// update texture once per frame (in blanking)
		if (top->sdl_sy == V_RES && top->sdl_sx == 0) {
			SDL_UpdateTexture(
			  sdl_texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
			SDL_RenderClear(sdl_renderer);
			SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
			SDL_RenderPresent(sdl_renderer);
			frame_count++;
		}

		top->eval();
	}

	// calculate frame rate
	uint64_t end_ticks = SDL_GetPerformanceCounter();
	double duration =
	  ((double)(end_ticks - start_ticks)) / SDL_GetPerformanceFrequency();
	double fps = (double)frame_count / duration;
	printf(
	  "Number of frames: %lu \nFrames per second: %.1f\n", frame_count, fps);

	top->final(); // simulation done

	SDL_DestroyTexture(sdl_texture);
	SDL_DestroyRenderer(sdl_renderer);
	SDL_DestroyWindow(sdl_window);
	SDL_Quit();

	contextp->statsPrintSummary();
	return 0;
}