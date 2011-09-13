#include <Wire.h>
#include <Servo.h>

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
	Serial.print("\r\nStart");
	init_leds();
	acc.powerOn();

        if (acc.isConnected()) {
                log("connected");
        }
}
void log(String msg) {
                Serial.print("\r\n");
                Serial.print(millis());
                 Serial.print(": ");
                Serial.print(msg);
}
void logn(int msg) {
                Serial.print(msg);
}
void loop()
{
	byte err;
	byte idle;
	static byte count = 0;
	byte msg[3];
	long touchcount;

	if (acc.isConnected()) {
//                digitalWrite(LED_BUILTIN, HIGH);
 
		int len = acc.read(msg, sizeof(msg), 1);  
		int i;
		byte b;
		uint16_t val;
		int x, y;
		char c0;

		if (len > 0) {
                        log("msg[0]: "); logn(msg[0]);
                        log("msg[1]: "); logn(msg[1]);
                        log("msg[2]: "); logn(msg[2]);
                        digitalWrite(LED_BUILTIN, HIGH);

			// assumes only one command per packet
			if (msg[0] == 0x2) {
                                log("LED_RED command");
				if (msg[1] == 0x0)
					analogWrite(LED_RED, msg[2]);
			}
                        delay(100);
                        digitalWrite(LED_BUILTIN, LOW);
		}

		
	} else {
                digitalWrite(LED_RED, LOW);
                log("disconnected");
		// reset outputs to default values on disconnect
		//analogWrite(LED_RED, 255);
	}
	delay(10);
    
//       for (int i; i < 25 ; i++) { 
//            analogWrite(LED_BUILTIN, i*10);
//    	delay(50);
//       }
//       for (int i; i < 25 ; i++) { 
//            analogWrite(LED_RED, i*10);
//    	    delay(50);
//       }
//       
//       for (int i=25; i > 0; i--) { 
//        analogWrite(LED_RED, i*10);
//    	delay(50);
//       }
}

