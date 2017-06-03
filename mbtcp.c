/*
 * References:
 *
 * https://rt.wiki.kernel.org/index.php/RT_PREEMPT_HOWTO#A_Realtime_.22Hello_World.22_Example
 * http://libmodbus.org/docs/v3.0.6/
 * https://codezine.jp/article/detail/4700
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <sched.h>
#include <string.h>
#include <modbus.h>
#include <errno.h>
#include <signal.h>

#define NSEC_PER_SEC (1000000000) /* The number of nsecs per sec. */

#define MAX_NUM_REGISTERS (125) /* according to the specification. */

modbus_t *mb_ctx;
int num_registers = 0;
uint16_t communication_counter = 0;
volatile sig_atomic_t sigint = 0;

void usage(void) {
  fprintf(stderr, "Arguments: ip_address port interval_ns number_registers\n");
  exit(-1);  
}

void handle_signal(int signal) {
  fprintf(stderr, "Cought SIGINT\n");
  sigint = 1;
}

void rt_begin(void) {
  struct sched_param param;
  param.sched_priority = sched_get_priority_max(SCHED_FIFO);
  if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
    perror("Failed in sched_setscheduler()");
    exit(-1);
  }
}

void mb_begin(char* ip, int port) {
  mb_ctx = modbus_new_tcp(ip, port);
  if (mb_ctx == NULL) {
    fprintf(stderr, "Failed in modbus_new_tcp(): %s\n", modbus_strerror(errno));
    exit(-1);
  }
  fprintf(stderr, "Done modbus_new_tcp()\n");

  /*   modbus_set_debug(mb_ctx, 1); */

  if (modbus_connect(mb_ctx) == -1) {
    fprintf(stderr, "Failed in modbus_connect(): %s\n", modbus_strerror(errno));
    modbus_free(mb_ctx);
    exit(-1);
  }
  fprintf(stderr, "Done modbus_connect()\n");
}

void mb_end(void) {
  modbus_close(mb_ctx);
  fprintf(stderr, "Done modbus_close()\n");
  modbus_free(mb_ctx);
  fprintf(stderr, "Done modbus_free()\n");
}

void mb_rw(void) {
  static int addr;
  static int nb_r;
  static int nb;

  static uint16_t tab_reg[128];
  static int rc;

  static uint16_t tab_reg_out[128];

  static unsigned short int zero_len = 0;
  static unsigned short int data_len;

  addr = 0;
  nb_r = num_registers;
  while(nb_r > 0) {
    /*     fprintf(stderr, "(%d, %d)\n", addr, nb_r); */
    if (nb_r > MAX_NUM_REGISTERS) {
      nb = MAX_NUM_REGISTERS;
    } else {
      nb = nb_r;
    }

    rc = modbus_read_input_registers(mb_ctx, addr, nb, tab_reg);
    if (rc == -1) {
      fprintf(stderr, "Failed in modbus_read_registers(): %s\n", modbus_strerror(errno));
      fwrite(&zero_len, sizeof(unsigned short int), 1, stdout);
    } else {
      data_len = sizeof(uint16_t) * rc;
      /*       fprintf(stderr, "Read: %ld x %d = %d\n", sizeof(uint16_t), rc, data_len); */
      fwrite(&data_len, sizeof(unsigned short int), 1, stdout);
      fwrite(&tab_reg, sizeof(uint16_t), rc, stdout);
      /*       fprintf(stderr, "Wrote: %d => %ld\n", rc, wrote); */
    }

    nb_r -= nb;
    addr += nb;
  }
  fwrite(&zero_len, sizeof(unsigned short int), 1, stdout);

  communication_counter++;
  /*   tab_reg_out[0] = ((communication_counter & 0xff) << 8) | ((communication_counter >> 8) & 0xff); */
  tab_reg_out[0] = communication_counter;
  /*   fprintf(stderr, "Counter: %d\n", communication_counter); */
  modbus_write_registers(mb_ctx, 0, 1, tab_reg_out);
}

void main_loop(int interval) {
  struct timespec timer;
  struct timespec ttooutm;
  struct timespec ttooutr;

  clock_gettime(CLOCK_MONOTONIC, &timer);
  /* start after one second */
  timer.tv_sec++;

  while(!sigint) {
    /* wait until next shot */
    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &timer, NULL);

    clock_gettime(CLOCK_MONOTONIC_RAW, &ttooutm);
    clock_gettime(CLOCK_REALTIME, &ttooutr);
    fwrite(&timer.tv_sec, sizeof(time_t), 1, stdout);
    fwrite(&timer.tv_nsec, sizeof(long), 1, stdout);
    fwrite(&ttooutm.tv_sec, sizeof(time_t), 1, stdout);
    fwrite(&ttooutm.tv_nsec, sizeof(long), 1, stdout);
    fwrite(&ttooutr.tv_sec, sizeof(time_t), 1, stdout);
    fwrite(&ttooutr.tv_nsec, sizeof(long), 1, stdout);

    mb_rw();

    /* calculate next shot */
    timer.tv_nsec += interval;

    while (timer.tv_nsec >= NSEC_PER_SEC) {
      timer.tv_nsec -= NSEC_PER_SEC;
      timer.tv_sec++;
    }
  }
}

int main(int argc, char* argv[]) {
  int interval = 50000; /* 50us */

  rt_begin();

  if (SIG_ERR == signal(SIGINT, handle_signal)) {
    fprintf(stderr, "Failed in signal()\n");
    exit(-1);  
  }

  if(argc>=3) {
    mb_begin(argv[1], atoi(argv[2]));
  } else {
    usage();
  }

  if(argc>=4) {
    interval = atoi(argv[3]);
  }
  fprintf(stderr, "Interval [ns]: %d\n", interval);

  if(argc>=5) {
    num_registers = atoi(argv[4]);
  }
  fprintf(stderr, "Number of input registers to read: %d\n", num_registers);

  main_loop(interval);

  mb_end();
}
