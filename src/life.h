#ifndef LIFE_H
#define LIFE_H

#include <stdint.h>

#ifndef HEIGHT
#define HEIGHT 64
#endif

#ifndef WIDTH
#define WIDTH 128
#endif

#define BUFF_SIZE (HEIGHT * WIDTH / 8)

#ifdef __cplusplus
extern "C"
{
#endif

  typedef uint8_t buffer[BUFF_SIZE];

  uint8_t get_ceil (buffer ceils, uint8_t x, uint8_t y);

  void set_ceil (buffer ceils, uint8_t x, uint8_t y, uint8_t ceil);

  uint8_t get_neighbors (buffer ceils, uint8_t x, uint8_t y);

  void calculate_new_generation (buffer dest, buffer source);

  void clean (buffer buf);

  void glider (buffer ceils);

  void swap_buffers (buffer **a, buffer **b);

  void write_log (int msg);

#ifdef __cplusplus
}
#endif

#endif // LIFE_H
