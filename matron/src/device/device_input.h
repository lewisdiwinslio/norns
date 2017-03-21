#pragma once

#include <stdint.h>

#include <libevdev.h>
#include "device_common.h"

typedef uint8_t dev_vid_t;
typedef uint8_t dev_pid_t;
typedef uint16_t dev_code_t;

struct dev_input {
  struct dev_common base;
  struct libevdev *dev;
  // identifiers
  dev_vid_t vid;
  dev_pid_t pid;
  // count of supported event types
  int num_types;
  // array of supported event types
  uint8_t *types;
  // count of supported event codes per event type
  int *num_codes;
  // arrays of supported event codes per event type
  dev_code_t **codes;
};

extern int dev_input_init(void* self);
extern void* dev_input_start(void* self);
extern void dev_input_deinit(void* self);
