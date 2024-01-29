#include "life.h"
#include <Arduboy2Core.h>
#include <HardwareSerial.h>

Arduboy2Core arduboy;

uint8_t * bbuf;
uint8_t * fbuf;

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
draw_buffer (uint8_t * ceils)
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

  bbuf = create_buffer();
  fbuf = create_buffer();

  write_log(bbuf);                // 633
  write_log(fbuf);                // 0
  write_log (availableMemory ()); // 1013

  glider (fbuf);

  arduboy.boot ();
}

void
loop ()
{
  if (millis() % 500 != 0)
    return;

  draw_buffer (fbuf);
  calculate_new_generation (bbuf, fbuf);
  swap_buffers(&bbuf, &fbuf);
}

void
write_log (int msg)
{
  Serial.println (msg);
}
