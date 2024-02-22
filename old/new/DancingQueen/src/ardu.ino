#include <FastLED.h>
#include <PacketSerial.h>

PacketSerial myPacketSerial;

#define NUMLEDS 113
#define DATA_PIN 11
#define CLOCK_PIN 13
#define BAUDRATE 115200

CRGB leds[NUMLEDS];
byte buff[5];

void setup() {
  FastLED.addLeds<DOTSTAR, DATA_PIN, CLOCK_PIN, BGR>(leds, NUMLEDS);
  FastLED.clear();
  FastLED.show();
  myPacketSerial.begin(BAUDRATE);
  myPacketSerial.setPacketHandler(&onPacketReceived);
}

void loop() {
  myPacketSerial.update();
}

void onPacketReceived(const uint8_t* buff, size_t nb) {
  FastLED.clear();
  int nsuns = nb / 5;
  for (int sun = 0; sun < nsuns; sun++) {
    int offset = 5 * sun;
    CRGB color = CRGB(buff[offset + 0], buff[offset + 1], buff[offset + 2]);
    if (buff[offset + 3] > buff[offset + 4]) {
      for (int i = buff[offset + 3] - 1; i < NUMLEDS; i++) {
        leds[i] = color;
      }
      for (int i = 0; i < buff[offset + 4]; i++) {
        leds[i] = color;
      }
    } else {
      for (int i = buff[offset + 3] - 1; i < buff[offset + 4]; i++) {
        leds[i] = color;
      }
    }
  }
  FastLED.show();
}

