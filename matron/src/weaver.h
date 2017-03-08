#pragma once

#include "oracle.h"

// initialize the lua VM and run setup scripts
extern void w_init(void);

// run the user-defined startup routine
extern void w_user_startup(void);

// compile and execute a complete chunk of lua
// this blocks execution and access the VM directly;
// call it only from the main thread
extern void w_run_code(const char* code);

// handle a single line of user input
// this blocks execution and access the VM directly;
// call it only from the main thread
extern void w_handle_line(char* line);

//-------------------------
//---- c -> lua glue

//--- hardware input
extern void w_handle_grid_press(int x, int y);
extern void w_handle_grid_lift(int x, int y);

extern void w_handle_stick_axis(int stick, int axis, int value) ;
extern void w_handle_stick_button(int stick, int button, int value) ;
extern void w_handle_stick_hat(int stick, int hat, int value) ;
extern void w_handle_stick_ball(int stick, int ball, int xrel, int yrel) ;

//--- audio engine introspection
extern void w_handle_engine_report(const char** arr, const int num);
extern void w_handle_command_report(const struct engine_command* arr,
									const int num);

//--- timer bang handler
extern void w_handle_timer(const int idx, const int stage);
