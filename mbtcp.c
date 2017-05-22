#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <sched.h>
#include <string.h>
#include <modbus.h>

#define NSEC_PER_SEC    (1000000000) /* The number of nsecs per sec. */

modbus_t *ctx;

void modclose(void) {
  modbus_close(ctx);
  modbus_free(ctx);
}

int main(int argc, char* argv[])
{
  struct timespec t;
  struct timespec tt;
  struct sched_param param;
  int interval = 50000; /* 50us*/
  char *ip_address;
  int port = MODBUS_TCP_DEFAULT_PORT;
  uint16_t tab_reg[64];
  int rc;
  int i;
  int zero_len = 0;
  int data_len;

  /* Declare ourself as a real time task */

  param.sched_priority = sched_get_priority_max(SCHED_FIFO);
  if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
    perror("sched_setscheduler failed");
    exit(-1);
  }

  /* modbus */

  if(argc>=2) {
    ip_address = &argv[1];
  }

  if(argc>=3) {
    port = atoi(argv[2]);
  }

  ctx = modbus_new_tcp(ip_address, port);
  if (ctx == NULL) {
    fprintf(stderr, "Unable to allocate libmodbus context\n");
    exit(-1);
  }

  if (modbus_connect(ctx) == -1) {
    fprintf(stderr, "Connection failed: %s\n", modbus_strerror(errno));
    modbus_free(ctx);
    exit(-1);
  }

  atexit(modclose);

  /* interval */

  if(argc>=4) {
    interval = atoi(argv[3]);
  }

  clock_gettime(CLOCK_MONOTONIC ,&t);
  /* start after one second */
  t.tv_sec++;

  while(1) {
    /* wait until next shot */
    clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &t, NULL);

    clock_gettime(CLOCK_REALTIME, &tt);
    fwrite(&t.tv_sec, sizeof(time_t), 1, stdout);
    fwrite(&t.tv_nsec, sizeof(long), 1, stdout);
    fwrite(&tt.tv_sec, sizeof(time_t), 1, stdout);
    fwrite(&tt.tv_nsec, sizeof(long), 1, stdout);

    rc = modbus_read_registers(ctx, 0, 10, tab_reg);
    if (rc == -1) {
      fprintf(stderr, "%s\n", modbus_strerror(errno));
      fwrite(&zero_len, sizeof(int), 1, stdout);
    } else {
      data_len = sizeof(tab_reg) * rc;
      fwrite(&data_len, sizeof(int), 1, stdout);
      fwrite(&tab_reg, sizeof(uint16_t), rc, stdout);
      /* modbus_write_registers(modbus_t *ctx, int addr, int nb, const uint16_t *src) */
    }

    /* calculate next shot */
    t.tv_nsec += interval;

    while (t.tv_nsec >= NSEC_PER_SEC) {
      t.tv_nsec -= NSEC_PER_SEC;
      t.tv_sec++;
    }
  }
}
