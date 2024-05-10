///////////////////////////////////////
/// Audio
/// compile with
/// gcc media_brl4_7_audio.c -o testA -lm
///////////////////////////////////////
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <sys/types.h>
#include <string.h>
// interprocess comm
#include <sys/ipc.h> 
#include <sys/shm.h> 
#include <sys/mman.h>
#include <time.h>
// network stuff
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>  /* IP address conversion stuff */
#include <netdb.h> 

#include "address_map_arm_brl4.h"

// fixed point
#define float2fix30(a) ((int)((a)*1073741824)) // 2^30

//#define SWAP(X,Y) do{int temp=X; X=Y; Y=temp;}while(0) 

/* function prototypes */
//void VGA_text (int, int, char *);
//void VGA_box (int, int, int, int, short);
//void VGA_line(int, int, int, int, short) ;

// virtual to real address pointers

volatile unsigned int * red_LED_ptr = NULL ;
//volatile unsigned int * res_reg_ptr = NULL ;
//volatile unsigned int * stat_reg_ptr = NULL ;

// audio stuff
volatile unsigned int * audio_base_ptr = NULL ;
volatile unsigned int * audio_fifo_data_ptr = NULL ; //4bytes
volatile unsigned int * audio_left_data_ptr = NULL ; //8bytes
volatile unsigned int * audio_right_data_ptr = NULL ; //12bytes
// phase accumulator
unsigned int phase_acc, dds_incr ;
int sine_table[256];
// tones in Hz, 0 is a rest
float notes[9] = {262, 294, 330, 349, 392, 440, 494, 523, 0};
clock_t note_time ;

// the light weight buss base
void *h2p_lw_virtual_base;

// pixel buffer
volatile unsigned int * vga_pixel_ptr = NULL ;
void *vga_pixel_virtual_base;

// character buffer
volatile unsigned int * vga_char_ptr = NULL ;
void *vga_char_virtual_base;

// /dev/mem file descriptor
int fd;

// shared memory 
key_t mem_key=0xf0;
int shared_mem_id; 
int *shared_ptr;
int audio_time;
 
int main(void)
{
	// ======================================================
	// UDP stuff from
	// http://www.linuxhowtos.org/C_C++/socket.htm
	// source code: server_udp.c
	int sock, n, flags;
	unsigned int length;
	struct sockaddr_in server, from;
	struct hostent *hp;
	char buffer[256];
	int frequency = 0;
	
	// open socket and associate with remote IP address
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0) printf("socket\n\r");
	// set up socket receive function to noblock option
	flags = fcntl(sock, F_GETFL);
	flags |= O_NONBLOCK;
	fcntl(sock, F_SETFL, flags);
	// setup address
	length = sizeof(server);
	server.sin_family = AF_INET;
	server.sin_addr.s_addr=INADDR_ANY;
	// set IP port number
	server.sin_port = htons(9090);
	// associate remote IP address with socket
	if (bind(sock,(struct sockaddr *)&server,length)<0) printf("binding");
	length=sizeof(struct sockaddr_in);
	
	// generally should close socket, but this code does not
	//close(sock);
	// ======================================================
	
	// Declare volatile pointers to I/O registers (volatile 	// means that IO load and store instructions will be used 	// to access these pointer locations, 
	// instead of regular memory loads and stores) 

  	// === shared memory =======================
	// with video process
	shared_mem_id = shmget(mem_key, 100, IPC_CREAT | 0666);
	shared_ptr = shmat(shared_mem_id, NULL, 0);
	
	// === need to mmap: =======================
	// FPGA_CHAR_BASE
	// FPGA_ONCHIP_BASE      
	// HW_REGS_BASE        
  
	// === get FPGA addresses ==================
    // Open /dev/mem
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) 	{
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
    
    // get virtual addr that maps to physical
	h2p_lw_virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );	
	if( h2p_lw_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap1() failed...\n" );
		close( fd );
		return(1);
	}
    
    // Get the address that maps to the FPGA LED control 
	red_LED_ptr =(unsigned int *)(h2p_lw_virtual_base +  	 			LEDR_BASE);

	// address to resolution register
	//res_reg_ptr =(unsigned int *)(h2p_lw_virtual_base +  	 	//		resOffset);

	 //addr to vga status
	//stat_reg_ptr = (unsigned int *)(h2p_lw_virtual_base +  	 	//		statusOffset);

	// audio addresses
	// base address is control register
	audio_base_ptr = (unsigned int *)(h2p_lw_virtual_base +  	 			AUDIO_BASE);
	audio_fifo_data_ptr  = audio_base_ptr  + 1 ; // word
	audio_left_data_ptr = audio_base_ptr  + 2 ; // words
	audio_right_data_ptr = audio_base_ptr  + 3 ; // words

	// === get VGA char addr =====================
	// get virtual addr that maps to physical
	vga_char_virtual_base = mmap( NULL, FPGA_CHAR_SPAN, ( 	PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_CHAR_BASE );	
	if( vga_char_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap2() failed...\n" );
		close( fd );
		return(1);
	}
    
    // Get the address that maps to the FPGA LED control 
	vga_char_ptr =(unsigned int *)(vga_char_virtual_base);

	// === get VGA pixel addr ====================
	// get virtual addr that maps to physical
	vga_pixel_virtual_base = mmap( NULL, FPGA_ONCHIP_SPAN, ( 	PROT_READ | PROT_WRITE ), MAP_SHARED, fd, 			FPGA_ONCHIP_BASE);	
	if( vga_pixel_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap3() failed...\n" );
		close( fd );
		return(1);
	}
    
    // Get the address that maps to the FPGA pixel buffer
	vga_pixel_ptr =(unsigned int *)(vga_pixel_virtual_base);

	// ===========================================
	// build the DDS sine table
	int i;
	for(i=0; i<256; i++)
		sine_table[i] = float2fix30(sin(6.28*(float)i/256));
	// dds_incr = Fout * 2^32 / Fsample
	// dds_incr = 261.8 * 2^32 / 48000 = 261.8 * 89478.5 
	// dds_incr = 0x01000000 ; //187.5 Hz 
	dds_incr = 0 ; // silence
	
	while(1){	
			//sprintf(buffer,"start\n\r");
	    //n=sendto(sock, buffer, strlen(buffer),0,(const struct sockaddr *)&server, length);
    
    
    // check for UDP packet & get frequency
		n = recvfrom(sock,buffer,256,0,(struct sockaddr *)&from, &length);
		// was there actually a packet?
   
   
		if (n > 0){
			printf("Received a packet\n");
      sscanf(buffer, "%d", &frequency);
      
      //printf("Received: 0x%8x\n", (int) frequency);
			printf("%d\n\r",frequency);
		} 
		// compute frequency increment
		//dds_incr = (int) (frequency * 89478.5 );
		// copy note frequency to video process
		//*(shared_ptr+1) = frequency;
		
		// generate the sine wave
   /*
		int s_index ; // 8-bit sine table phase
		// load the FIFO until it is full
		while (((*audio_fifo_data_ptr>>24)& 0xff) > 1) {
			// do DDS
			phase_acc = (phase_acc + dds_incr);
			s_index = phase_acc>>24;
			*audio_left_data_ptr = sine_table[s_index];
			*audio_right_data_ptr = sine_table[s_index];
			// share the audio sample time with other processes
			audio_time++ ;
			*shared_ptr = audio_time/48000 ;
		} // end while (((*audio		*/
	} // end while(1)
} // end main
