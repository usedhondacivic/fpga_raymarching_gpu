// g++ main.c ../Final/final.c ../Final-visuals/main.c -lm -lpthread -o final-combined && ./final-combined 

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include "../Final-visuals/main.h"
#include "../Final/final.h"

arg pthread_args;

int main(void){
	pthread_t p_audio_thread, p_visual_thread;
	int  iret1, iret2;
	pthread_args.energy = 0.2;
	pthread_args.mood = POSITIVE;
	iret1 = pthread_create(&p_audio_thread, NULL, audio_thread, (void*) &pthread_args);
	iret2 = pthread_create(&p_visual_thread, NULL, visual_thread, (void*) &pthread_args);
	pthread_join( p_audio_thread, NULL);  
	pthread_join( p_visual_thread, NULL);  
    return 0;
}