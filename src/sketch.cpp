#include "life.h"
#include <Arduboy2Core.h>

Arduboy2Core arduboy;

buffer buffer1;
buffer buffer2;

buffer *bbuf = &buffer1;
buffer *fbuf = &buffer2;

void
draw_buffer (buffer ceils)
{
  for (int i = 0; i < BUFF_SIZE; i++)
    arduboy.SPItransfer (ceils[i]);
}

void
setup ()
{
  clean(buffer1);
  clean(buffer2);

  glider (*fbuf);

  arduboy.boot ();
}

void
loop ()
{
  draw_buffer (*fbuf);
  calculate_new_generation (*bbuf, *fbuf);
  swap_buffers(&bbuf, &fbuf);
}

