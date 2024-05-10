#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pthread.h>
#include "final.h"

time_t getFileCreationTime(char *path) {
    struct stat attr;
    stat(path, &attr);
    time_t modify_time = attr.st_mtime;
    //printf("Last modified time: %lld", modify_time);
    return modify_time;
}

void readFile(FILE* fp,  float* energy, int* mood){
  if(fscanf(fp, "%f,%d", energy, mood) == 2){
    printf("Scan successful\n");
  }
  else{
    printf("Parsing failed\n");
  }
}

void *audio_thread(void *args){
  time_t initial_time = getFileCreationTime("send_data.txt");
  printf("First modified time: %lld\n", initial_time);
  //return 1;
  time_t ntime;
   
  float energy; // From 0.0 to 1.0, index describing how energetic a song is (0 being not energetic at all, 1 being extremely energetic)
  int mood; //0 = happy, 1 = neutral, 2 = angry, 3 = sad
  FILE* file;
  while(1){
    ntime = getFileCreationTime("send_data.txt");
    if(ntime != initial_time){
      printf("It's changed\n");
      initial_time = ntime;
      file = fopen("send_data.txt", "r");
      readFile(file, &energy, &mood);
      usleep(1000);
      printf("%f | %d\n", energy, mood);
      ((arg *)args)->mood = (enum MOOD)mood;
      ((arg *)args)->energy = energy;
      
      usleep(1000);
      fclose(file);
      //return 1;
    }
    usleep(1000);
  }
}

// int main() {
//   time_t initial_time = getFileCreationTime("send_data.txt");
//   printf("First modified time: %lld\n", initial_time);
//   //return 1;
//   time_t ntime;
  
  
//   float energy; // From 0.0 to 1.0, index describing how energetic a song is (0 being not energetic at all, 1 being extremely energetic)
//   int mood; //0 = happy, 1 = neutral, 2 = angry, 3 = sad
//   FILE* file;
//   while(1){
//     ntime = getFileCreationTime("send_data.txt");
//     if(ntime != initial_time){
//       printf("It's changed\n");
//       initial_time = ntime;
//       file = fopen("send_data.txt", "r");
//       readFile(file, &energy, &mood);
//       usleep(1000);
//       printf("%f | %d\n", energy, mood);
      
//       usleep(1000);
//       fclose(file);
//       //return 1;
//     }
//     usleep(1000);
//   }
  
//   return 0;
// }
