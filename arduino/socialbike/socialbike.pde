#include <Wire.h>
#include <Servo.h>

#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

#define  KEY_LOCKER     11

#define  SHACKLE_FEELER 41
#define  SHACKLE_OUTPUT 43

/*
   AndroidAccessory acc("SocialBike",
   "SocialBike",
   "SocialBike Lock",
   "1.0",
   "http://www.c-base.org",
   "3245678878765432");
 */

AndroidAccessory acc("Google, Inc.",
				"DemoKit",
				"DemoKit Arduino Board",
				"1.0",
				"http://www.android.com",
				"0000000012345678");

Servo keyLocker;

void setup();
void loop();

void init_locker()
{
		keyLocker.attach(KEY_LOCKER);
		keyLocker.write(90); 
}

void init_shackle_feeler()
{
		pinMode(SHACKLE_FEELER, INPUT);
		pinMode(SHACKLE_OUTPUT, OUTPUT);
		digitalWrite(SHACKLE_OUTPUT, HIGH);
}

byte feelerInput;

void setup()
{
		Serial.begin(115200);
		Serial.print("\r\nStart");

		init_locker();
		init_shackle_feeler();

		acc.powerOn();
}

void loop()
{
		byte err;
		byte idle;
		static byte count = 0;
		byte message[3];

		if (acc.isConnected()) {
				int len = acc.read(message, sizeof(message), 1);
				int i;
				byte b;
				uint16_t val;
				int x, y;
				char c0;

				if (len > 0) {
						// assumes only one command per packet
						if (message[0] == 0x2) {
								if (message[1] == 0x10) {
										keyLocker.write(map(message[2], 0, 255, 0, 180));
										Serial.print("\r\nMESSAGE wrote to keyLocker");
								}
						}

						message[0] = 0x1;
						b = digitalRead(SHACKLE_FEELER);
						if (b == HIGH) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: HIGH");
						} else if (b == LOW) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: LOW");
						} else {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: WTF");
						}

						if (b != feelerInput) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER");
								message[1] = 0;
								message[2] = b ? 0 : 1;
								acc.write(message, 3);
								feelerInput = b;
						}
				}
		} else {
				keyLocker.write(90);
		}

		delay(10);
}
