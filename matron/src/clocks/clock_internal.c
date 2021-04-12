#include <math.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "clock.h"
#include "clock_scheduler.h"
#include "clock_internal.h"

#define CLOCK_INTERNAL_TICKS_PER_BEAT 24

typedef struct {
    double beat_duration;
    double tick_duration;
    struct timespec tick_ts;
} clock_internal_tempo_t;

static pthread_t clock_internal_thread;
static clock_reference_t clock_internal_reference;
static int clock_internal_counter;

static clock_internal_tempo_t clock_internal_tempo;
static pthread_mutex_t clock_internal_tempo_lock;

static void *clock_internal_thread_run(void *p) {
    (void)p;
    struct timespec ts;
    double beat_duration;
    double reference_beat;

    while (true) {
        pthread_mutex_lock(&clock_internal_tempo_lock);

        beat_duration = clock_internal_tempo.beat_duration;
        ts.tv_sec = clock_internal_tempo.tick_ts.tv_sec;
        ts.tv_nsec = clock_internal_tempo.tick_ts.tv_nsec;

        pthread_mutex_unlock(&clock_internal_tempo_lock);

        clock_nanosleep(CLOCK_MONOTONIC, 0, &ts, NULL);

        clock_internal_counter++;
        reference_beat = (double) clock_internal_counter / CLOCK_INTERNAL_TICKS_PER_BEAT;
        clock_update_source_reference(&clock_internal_reference, reference_beat, beat_duration);
    }

    return NULL;
}

static void clock_internal_start() {
    pthread_attr_t attr;

    pthread_attr_init(&attr);
    pthread_create(&clock_internal_thread, &attr, &clock_internal_thread_run, NULL);
    pthread_attr_destroy(&attr);
}

void clock_internal_init() {
    pthread_mutex_init(&clock_internal_tempo_lock, NULL);
    clock_reference_init(&clock_internal_reference);
    clock_internal_counter = -1;
    clock_internal_start();
}


void clock_internal_set_tempo(double bpm) {
    pthread_mutex_lock(&clock_internal_tempo_lock);

    clock_internal_tempo.beat_duration = 60.0 / bpm;
    clock_internal_tempo.tick_duration = clock_internal_tempo.beat_duration / CLOCK_INTERNAL_TICKS_PER_BEAT;

    clock_internal_tempo.tick_ts.tv_sec = clock_internal_tempo.tick_duration;
    clock_internal_tempo.tick_ts.tv_nsec = (clock_internal_tempo.tick_duration - floor(clock_internal_tempo.tick_duration)) * 1000000000;

    pthread_mutex_unlock(&clock_internal_tempo_lock);

}

void clock_internal_restart() {
    pthread_mutex_lock(&clock_internal_tempo_lock);

    clock_start_from_source(CLOCK_SOURCE_INTERNAL);
    clock_internal_counter = -1;
    clock_scheduler_reset_sync_events();

    pthread_mutex_unlock(&clock_internal_tempo_lock);
}

void clock_internal_stop() {
    clock_stop_from_source(CLOCK_SOURCE_INTERNAL);
}

double clock_internal_get_beat() {
    return clock_get_reference_beat(&clock_internal_reference);
}

double clock_internal_get_tempo() {
    return clock_get_reference_tempo(&clock_internal_reference);
}
