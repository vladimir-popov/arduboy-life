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

  uint8_t * create_buffer();

  uint8_t get_ceil (uint8_t * ceils, uint8_t x, uint8_t y);

  void set_ceil (uint8_t * ceils, uint8_t x, uint8_t y, uint8_t ceil);

  uint8_t get_neighbors (uint8_t * ceils, uint8_t x, uint8_t y);

  void calculate_new_generation (uint8_t * dest, uint8_t * source);

  void clean (uint8_t * buf);

  void glider (uint8_t * ceils);

  void swap_buffers (uint8_t **a, uint8_t **b);

  void write_log (int msg);

#ifdef __cplusplus
}
#endif

#endif // LIFE_H
