#include "life.h"
#include "unity.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


char *
render (buffer buf, int h, int w)
{
  char *str = malloc (sizeof (char) * (h * w + h + 2));
  int s = 0;
  str[s++] = '\n';
  for (int j = 0; j < h; j++)
    {
      for (int i = 0; i < w; i++)
        {
          str[s++] = get_ceil (buf, i, j) ? '*' : '.';
        }
      str[s++] = '\n';
    }
  str[s++] = '\0';
  return str;
}

static void
print_render (buffer buf, int h, int w)
{
  char *str = render (buf, h, w);
  printf ("%s", str);
  free (str);
}

/**
 *  .....  .....  .....  .....  .....
 *  ..*..  .*...  ..*..  .....  .....
 *  *.*..  ..**.  ...*.  .*.*.  ...*.
 *  .**..  .**..  .***.  ..**.  .*.*.
 *  .....  .....  .....  ..*..  ..**.
 */
uint8_t gliders[5][8]
    = { { 0b100, 0b1000, 0b1110, 0b0, 0b0, 0b0, 0b0, 0b0 },
        { 0b0, 0b1010, 0b1100, 0b100, 0b0, 0b0, 0b0, 0b0 },
        { 0b0, 0b1000, 0b1010, 0b1100, 0b0, 0b0, 0b0, 0b0 },
        { 0b0, 0b100, 0b11000, 0b1100, 0b0, 0b0, 0b0, 0b0 },
        { 0b0, 0b1000, 0b10000, 0b11100, 0b0, 0b0, 0b0, 0b0 } };

buffer buffer1;
buffer buffer2;
buffer *bbuf = &buffer1;
buffer *fbuf = &buffer2;

void
setUp (void)
{
  clean (buffer1);
  clean (buffer2);
}

void
tearDown (void)
{
}

static void
test_glider (void)
{
  glider (buffer1);
  char *msg = render (buffer1, 8, 8);
  TEST_ASSERT_EQUAL_UINT8_ARRAY_MESSAGE (gliders[2], buffer1, 8, msg);
  free (msg);
}

static void
test_glider_flight (void)
{
  memcpy (*fbuf, gliders[0], 8);

  char *msg = malloc (sizeof (char) * 7);
  for (int i = 0; i < 5; i++)
    {
      // printf ("\nExpected:");
      // print_render (gliders[i], 8, 8);
      // printf ("Actual:");
      // print_render (*fbuf, 8, 8);
      sprintf (msg, "case %d", i);
      TEST_ASSERT_EQUAL_UINT8_ARRAY_MESSAGE (gliders[i], *fbuf, 8, msg);
      calculate_new_generation (*bbuf, *fbuf);
      swap_buffers (&bbuf, &fbuf);
    }
  free (msg);
}

int
main (void)
{
  UnityBegin ("test.c");

  RUN_TEST (test_glider);
  RUN_TEST (test_glider_flight);

  return UnityEnd ();
}
