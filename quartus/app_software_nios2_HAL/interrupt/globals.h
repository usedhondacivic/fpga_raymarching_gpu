/* The base addresses of devices are listed in the BSP/system.h file*/
#include "system.h"

/* include HAL device driver functions for the parallel port and audio device */
#include "altera_up_avalon_audio.h"
#include "altera_avalon_pio_regs.h"

#include "sys/alt_stdio.h"
#include "sys/alt_irq.h"

/* This stucture holds a pointer to each open I/O device */
struct alt_up_dev {
	alt_up_audio_dev *audio_dev;
};

