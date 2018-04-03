/* i2c.c
 *
 * hp driver: TPA6130A2
 * digipots: DS1881
 *
 */

#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "i2c.h"

#define ADDR_HP 0x60
#define ADDR_IN 0x29

static int file;
static char buf[10];

void i2c_init(void) {
    char filename[40];

    sprintf(filename,"/dev/i2c-1");
    if( ( file = open(filename,O_RDWR | O_NONBLOCK) ) < 0 ) {
        fprintf(stderr, "ERROR (i2c) failed to open bus\n");
        return;
    }

    // setup peripherals

    // enable hp
    if(ioctl(file,I2C_SLAVE,ADDR_HP) < 0) {
        fprintf(stderr,
            "ERROR (i2c) failed to acquire bus access and/or talk to slave\n");
        return;
    }
    buf[0] = 1; // reg for settings p21
    buf[1] = 192;
    if (write(file,buf,2) != 2) {
        fprintf(stderr, "ERROR (i2c/hp) failed to write\n");
        return;
    }

    // set up digipot audio in
    if(ioctl(file,I2C_SLAVE,ADDR_IN) < 0) {
        fprintf(stderr,
            "ERROR (i2c) failed to acquire bus access and/or talk to slave\n");
        return;
    }

    buf[0] = 0b10000010;
    if (write(file,buf,1) != 1) {
        fprintf(stderr, "ERROR (i2c/gain) failed to write\n");
        return;
    }
}

void i2c_hp(int level) {
    if(level < 0) {
        level = 0;
    }
    else if(level > 63) {
        level = 63;
    }

    if(ioctl(file,I2C_SLAVE,ADDR_HP) < 0) {
        fprintf(stderr,
            "ERROR (i2c) failed to acquire bus access and/or talk to slave\n");
        return;
    }
    buf[0] = 2; // reg for set level p17
    buf[1] = level;
    if (write(file,buf,2) != 2) {
        fprintf(stderr, "ERROR (i2c/hp) failed to write\n");
        return;
    }
}

void i2c_gain(int level, int ch) {
    if(level < 0) {
        level = 0;
    }
    else if(level > 63) {
        level = 63;
    }

    level = 63 - level;

    if(ch == 1) {
        ch = 0b01000000;
    }

    if(ioctl(file,I2C_SLAVE,ADDR_IN) < 0) {
        fprintf(stderr,
            "ERROR (i2c) failed to acquire bus access and/or talk to slave\n");
        return;
    }
    buf[0] = level | ch; // p10
    // FIXME: this should be better than a sleep loop
    while (write(file,buf,1) != 1) {
        //fprintf(stderr, "ERROR (i2c/gain) failed to write (level set)\n");
        //return;
        sleep(0.001);
    }
}
