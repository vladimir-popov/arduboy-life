#include "life.h"
#include <Arduboy2Core.h>
#include <HardwareSerial.h>

Arduboy2Core arduboy;

buffer buffer1;
buffer buffer2;

buffer *bbuf = &buffer1;
buffer *fbuf = &buffer2;

static int
availableMemory ()
{
  int size = 2512;
  byte *buf;
  while ((buf = (byte *)malloc (--size)) == NULL)
    ;
  free (buf);
  return size;
}

void
draw_buffer (buffer ceils)
{
  for (int i = 0; i < BUFF_SIZE; i++)
    arduboy.SPItransfer (ceils[i]);
}

void
setup ()
{
  // Initialize serial and wait for port to open:
  Serial.begin (9600);
  while (!Serial)
    ; // wait for serial port to connect. Needed for native USB port only 

  clean(buffer1);
  clean(buffer2);

  glider (*fbuf);

  arduboy.boot ();
}

void
loop ()
{
  if (millis() % 500 != 0)
    return;

  draw_buffer (*fbuf);
  calculate_new_generation (*bbuf, *fbuf);
  swap_buffers(&bbuf, &fbuf);
}

void
write_log (int msg)
{
  Serial.println (msg);
}
