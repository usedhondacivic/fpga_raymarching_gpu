#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

int main() {
    int serial_port;
    struct termios tty;

    serial_port = open("/dev/ttyS0", O_RDWR); // Change ttyUSB0 to your serial port

    if(serial_port < 0) {
        perror("Error opening serial port");
        return 1;
    }

    if(tcgetattr(serial_port, &tty) != 0) {
        perror("Error getting serial port attributes");
        return 1;
    }

    // Set baud rate to 9600
    cfsetospeed(&tty, B115200);
    cfsetispeed(&tty, B115200);

    // Set other serial port settings
    tty.c_cflag &= ~PARENB; // Disable parity
    tty.c_cflag &= ~CSTOPB; // One stop bit
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8;     // 8 bits per byte
    tty.c_cflag &= ~CRTSCTS; // Disable hardware flow control

    // Apply settings
    if(tcsetattr(serial_port, TCSANOW, &tty) != 0) {
        perror("Error setting serial port attributes");
        return 1;
    }

    // Read data from serial port
    char buffer[256];
    int n = 0;
    while(1) {
        n = read(serial_port, &buffer, sizeof(buffer));
        if(n > 0) {
            buffer[n] = '\0'; // Null-terminate the received data
            printf("Received data: %s", buffer);
        }
        usleep(100000); // Sleep for 100ms
    }

    close(serial_port);
    return 0;
}