#include "life.h"
#include <stdint.h>
#include <stdlib.h>

#define BIT(bit) (1 << (bit))
#define is_outside(buf, x, y) (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT)

uint8_t
get_ceil (buffer ceils, uint8_t x, uint8_t y)
{
  if (is_outside (ceils, x, y))
    return 0;

  uint8_t row = y / 8;
  uint8_t bit_position = y % 8;
  return (ceils[WIDTH * row + x] & (1 << bit_position)) >> bit_position;
}

void
set_ceil (buffer ceils, uint8_t x, uint8_t y, uint8_t ceil)
{
  if (is_outside (ceils, x, y))
    return;

  uint8_t row = y / 8;
  uint8_t bit_position = y % 8;
  if (ceil)
    ceils[(row * WIDTH) + x] |= BIT (bit_position);
  else
    ceils[(row * WIDTH) + x] &= ~(BIT (bit_position));
}

uint8_t
get_neighbors (buffer ceils, uint8_t x, uint8_t y)
{
  uint8_t sum = 0;
  for (uint8_t i = x - 1; i <= x + 1; i++)
    for (uint8_t j = y - 1; j <= y + 1; j++)
      {
        if (i == x && j == y)
          continue;
        sum += get_ceil (ceils, i, j);
      }
  return sum;
}

void
calculate_new_generation (buffer dest, buffer source)
{
  for (uint8_t x = 0; x < WIDTH; x++)
    for (uint8_t y = 0; y < HEIGHT; y++)
      {
        // cleanup:
        set_ceil (dest, x, y, 0);
        uint8_t nbrs = get_neighbors (source, x, y);
        uint8_t ceil = get_ceil (source, x, y);
        // Any live cell with fewer than two live neighbours dies, as if by
        // underpopulation.
        if (nbrs < 2 && ceil)
          set_ceil (dest, x, y, 0);
        // Any live cell with two or three live neighbours lives on to the
        // next generation.
        if ((nbrs == 2 || nbrs == 3) && ceil)
          set_ceil (dest, x, y, 1);
        // Any live cell with more than three live neighbours dies, as if by
        // overpopulation.
        if (nbrs > 3 && ceil)
          set_ceil (dest, x, y, 0);
        // Any dead cell with exactly three live neighbours becomes a live
        // cell, as if by reproduction.
        if (nbrs == 3 && !ceil)
          set_ceil (dest, x, y, 1);
      }
}

void
clean (buffer buf)
{
  for (int i = 0; i < BUFF_SIZE; i++)
    buf[i] = 0;
}

/**
 *  0000
 *  0010
 *  0001
 *  0111
 */
void
glider (buffer ceils)
{
  ceils[0] = 0b0;
  ceils[1] = 0b1000;
  ceils[2] = 0b1010;
  ceils[3] = 0b1100;
}

void
swap_buffers (buffer **a, buffer **b)
{
  buffer *t = *a;
  *a = *b;
  *b = t;
}
