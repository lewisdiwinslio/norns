#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "device.h"

#define TEST_NULL_AND_FREE(p) if( (p) != NULL ) { free(p); }

// start the rx thread for a device
static int dev_start(union dev *d);

union dev *dev_new(device_t type, const char *path) {
    union dev *d = calloc( 1, sizeof(union dev) );
    if(!d) {return NULL; }
    // initialize the base class
    d->base.type = type;
    d->base.path = malloc(strlen(path) + 1);
    strcpy(d->base.path, path);
    // initialize the subclass
    switch(type) {
    case DEV_TYPE_MONOME:
        if (dev_monome_init(d) < 0) {
            goto err_init;
        };
        break;
    case DEV_TYPE_HID:
        if (dev_hid_init(d, false) < 0) {
            goto err_init;
        }
        break;
    default:
        printf(
            "calling device.c:dev_new() with unkmown device type; this is an error!");
        goto err_init;
    }
    // start the thread
    dev_start(d);
    return d;

err_init:
    free(d);
    return NULL;
}

int dev_delete(union dev *d) {
    printf("dev_delete()\n"); fflush(stdout);
    int ret = pthread_cancel(d->base.tid);
    if(ret) {
        printf("dev_delete(): error in pthread_cancel(): %d\n", ret);
        /// FIXME: getting this error on every device removal (double delete?)
        if(ret == ESRCH) { printf("no such thread. (this is a known error)\n"); }
        fflush(stdout);
        return -1;
    }
    ret = pthread_join(d->base.tid, NULL); // wait before free
    if(ret) {
        printf("dev_delete(): error in pthread_join(): %d\n", ret);
        fflush(stdout);
        return -1;
    }
    d->base.deinit(d);
    TEST_NULL_AND_FREE(d->base.path);
    TEST_NULL_AND_FREE(d->base.serial);
    TEST_NULL_AND_FREE(d->base.name);
    free(d);
    return 0;
}

int dev_start(union dev *d) {
    pthread_attr_t attr;
    int ret;

    if (d->base.start == NULL) {
        return -1;
    }

    ret = pthread_attr_init(&attr);
    if(ret) {
        printf("m_init(): error on thread attributes \n"); fflush(stdout);
        return -1;
    }
    ret = pthread_create(&d->base.tid, &attr, d->base.start, d);
    pthread_attr_destroy(&attr);
    if(ret) {
        printf("m_init(): error creating thread\n"); fflush(stdout);
        return -1;
    }
    return 0;
}

int dev_id(union dev *d) {
    return d->base.id;
}

const char *dev_serial(union dev *d) {
    return d->base.serial;
}

const char *dev_name(union dev *d) {
    return d->base.name;
}
