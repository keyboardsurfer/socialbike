#include <Wire.h>
#include <Servo.h>

#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

#define  KEY_LOCKER     11

#define  SHACKLE_FEELER 41
#define  SHACKLE_OUTPUT 43


AndroidAccessory acc("SocialBike",
				"Social Bike Lock",
				"SocialBike Lock",
				"1.0",
				"http://www.c-base.org",
				"3245678878765432");
/*
   AndroidAccessory acc("Google, Inc.",
   "DemoKit",
   "DemoKit Arduino Board",
   "1.0",
   "http://www.android.com",
   "0000000012345678");

 */
Servo keyLocker;
int minLockServo = 0;
int maxLockServo = 0;
int minAnalogIn = 0;
int maxAnalogIn = 0;

void setup();
void loop();
void calibrateLock();

//helper methods
void writeIntToEEPROM(int value, int EEPROMaddress);
int readIntFromEEPROM(int EEPROMaddress);

void init_locker()
{
  keyLockerValue = keyMinValue;
  keyLocker.attach(KEY_LOCKER);
  keyLocker.write(keyLockerValue);
}

void init_shackle_feeler()
{
		pinMode(SHACKLE_FEELER, INPUT);
		pinMode(SHACKLE_OUTPUT, OUTPUT);
		digitalWrite(SHACKLE_OUTPUT, HIGH);
}

byte feelerInput;
bool shackleCheck = true;


void resetCalibration(){
  EEPROM.write(1,0);
  EEPROM.write(2,0);
} 
void calibrateLock()
{
  if (EEPROM.read(1) == 9 && EEPROM.read(2) == 9){
    minLockServo = readIntFromEEPROM(3);
    maxLockServo = readIntFromEEPROM(5);
    minAnalogIn = readIntFromEEPROM(7);
    maxAnalogIn = readIntFromEEPROM(9);
    return;
  }
  keyLocker.write(minLockServo);
  minAnalogIn = analogRead(sensorPin1);
  maxAnalogIn = minAnalogIn;
  int lastPotiChange = 0;
  for(int i = minLockServo; i< 180; i++={
    int potiRead = analogRead(sensorPin1)
    if(potiRead < minAnalogIn){
      minAnalogIn = potiRead;
      lastPotiChange = i;
    }
    if(potiRead > maxAnalogIn){
      maxAnalogIn = potiRead;
      lastPotiChange = i;
    }
    if(lastPotiChange - i >= 5){
      maxLockServo = i-10;
      break;
    } 
  }
  
  writeIntToEEPROM(minLockServo, 3);
  writeIntToEEPROM(maxLockServo, 5);
  writeIntToEEPROM(minAnalogIn, 7);
  writeIntToEEPROM(maxAnalogIn, 9);
}

void setup()
{
		Serial.begin(115200);
		Serial.print("\r\nStart");
                calibrateLock();
		init_locker();
		init_shackle_feeler();

		acc.powerOn();
}

void loop()
{
		byte message[3];

		if (acc.isConnected()) {
				int length = acc.read(message, sizeof(message), 1);
				byte shackleFeeler;

				if (length > 0) {
						// assumes only one command per packet
						if (message[0] == 0x2) {
								if (message[1] == 0x10) {
										keyLocker.write(map(message[2], 0, 255, 0, 180));
										Serial.print("\r\nMESSAGE wrote to keyLocker");
								}
						}

						if (message[0] == 0x3 && message[1] == 0x0) {
								Serial.print("\r\nShackle toggle");
								if (shackleCheck) {
										shackleCheck = false;
								} else {
										shackleCheck = true;
								}
						}

				}
				if (shackleCheck) {

						shackleFeeler = digitalRead(SHACKLE_FEELER);
						if (shackleFeeler == HIGH) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: HIGH");
						} else if (shackleFeeler == LOW) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: LOW");
						} else {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: WTF");
						}

						if (shackleFeeler != feelerInput) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER");
								message[1] = 0;
								message[2] = shackleFeeler ? 0 : 1;
								acc.write(message, 3);
								feelerInput = shackleFeeler;
						}
				}
                
           
		} else {
                  
		}

                  keyLocker.write(keyLockerValue);
                  if (keyLockerValue == keyMaxValue){
                  keyStepper = -1;
                  }
                  if (keyLockerValue == keyMinValue){
                  keyStepper = 1;
                  }
                  keyLockerValue += keyStepper;

		delay(10);
}

//helper stuff

void writeIntToEEPROM(int value, int EEPROMaddress){
  byte a1 = (value >> 8);
  byte a2 = (value);
  EEPROM.write(a1,EEPROMaddress);
  EEPROM.write(a2,EEPROMaddress+1);
}

int readIntFromEEPROM(int EEPROMaddress){
  return EEPROM.read(EEPROMaddress) << 8 | EEPROM.read(EEPROMaddress+1);
}

