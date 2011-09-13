#include <Wire.h>
#include <Servo.h>

#include <avr/pgmspace.h>
#include <EEPROM.h>
#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

#define  LED_BUILTIN   13
#define  LED_RED       12

AndroidAccessory acc("Google, Inc.",
		     "DemoKit",
		     "DemoKit Arduino Board",
		     "1.0",
		     "http://www.android.com",
		     "0000000012345678");
int a = 0;
int value;

void setup();
void loop();
void log(String msg);
void logn(int msg);

void init_leds()
{
	digitalWrite(LED_RED, LOW);
	pinMode(LED_RED, OUTPUT);
	digitalWrite(LED_BUILTIN, LOW);
	pinMode(LED_BUILTIN, OUTPUT);
}

void setup()
{
	Serial.begin(115200);
	Serial.println("Start");
	init_leds();
	acc.powerOn();

        if (acc.isConnected()) {
                log("connected");
        }
        
//        for (int i = 0; i < 512; i++) {
//          EEPROM.write(i, i);
//        }

}
void log(String msg) {
//                Serial.print("");
                Serial.print(millis());
                 Serial.print(": ");
                Serial.println(msg);
}
void lognln(int msg) {
                Serial.println(msg);
                Serial.print("\n\r");
}
void logn(int msg) {
                Serial.println(msg);
}
void loop()
{
	byte err;
	byte idle;
	static byte count = 0;
	byte msg[3];
	long touchcount;

        int value = EEPROM.read(a);

        Serial.print(a);
        Serial.print("\t");
        Serial.print(value);
        Serial.println();
  
        a = a + 1;
  
        if (a == 4096) {
          a = 0;
        }
  
//        delay(500);
}

