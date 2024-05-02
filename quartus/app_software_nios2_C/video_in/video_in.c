#include "address_map_nios2.h"

#define VIDEO_IN_ENABLE 0x00000004

/* This program demonstrates use of video-in and edge detection in the computer.
 *
 * It performs the following: 
 * 	1. enables the video-in
 * 	2. changes between regular video and edge detection based upon SW[0]
 * 	3. when a key is pressed takes a picture: ie. captures a current frame and stops the video in
 */
int main(void)
{
	volatile int * video_in_ptr	= (int *) VIDEO_IN_BASE;
	volatile int * KEY_ptr			= (int *) KEY_BASE;
	volatile int * SW_ptr			= (int *) SW_BASE;
	
	int video_in			= VIDEO_IN_ENABLE;
   *(video_in_ptr + 3)	= video_in;			// Enable the video input
	*(KEY_ptr + 3)	= 0xF;						// Make sure the edge capture register is cleared

	while(1)
	{
		int keys = *(KEY_ptr + 3);				// Read edge capture register
		if (keys != 0x0) {
			video_in ^= VIDEO_IN_ENABLE;		// Toggle between picture and video
		   *(video_in_ptr + 3) = video_in;		
			*(KEY_ptr + 3) = keys;				// Clear edge capture register
		}

		int switches = *SW_ptr;					// Toggle between video and edge detection
		*(video_in_ptr + 4) = (switches & 0x1);
	}
}
