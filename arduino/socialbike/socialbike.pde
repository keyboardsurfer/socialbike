#include <Wire.h>
#include <Servo.h>
#include <EEPROM.h>
#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

#define  KEY_LOCKER     11

#define  SHACKLE_FEELER 41
#define  SHACKLE_OUTPUT 43
#define  sensorPin1     1


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
int keyLockerValue;
int keyStepper;
int keyMaxValue;
int keyMinValue;

int minLockServo;
int maxLockServo;
int minAnalogIn;
int maxAnalogIn;


void setup();
void loop();

void resetCalibration();
void calibrateLock();

void openLock();
void closeLock();
boolean lockIsOpen();

//helper methods
void writeIntToEEPROM(int value, int EEPROMaddress);
int readIntFromEEPROM(int EEPROMaddress);
int potiRead(int iterations);

void init_locker()
{
		keyStepper = 1;
		keyMaxValue = 100;
		keyMinValue = 0;
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
bool shackleCheck = false;

void setup()
{
		Serial.begin(115200);
		Serial.print("\r\nStart");

                

		init_locker();
		init_shackle_feeler();

    calibrateLock();

		acc.powerOn();
}

void loop()
{
  if (Serial.available() > 0) {
    byte inChar = Serial.read();
      if (inChar == 'd') {
        if (lockIsOpen()){
          Serial.println("the lock is open");
        }
        else{
          Serial.println("the lock is closed");
        }
      }
      else if (inChar == 'o') {
        openLock();
      }
      else if (inChar == 'c') {
        closeLock();
      }
      else if (inChar == 'h') {
        Serial.println("possible commands: [d]ebug [o]pen [c]lose");
      }
  }
  
		byte message[3];

		if (acc.isConnected()) {
				int length = acc.read(message, sizeof(message), 1);
				byte shackleFeeler;

				if (length > 0) {
						Serial.print("\r\n Received stuff: ");
						Serial.print("\r\n message size is: ");
						Serial.print(sizeof(message), DEC);
						Serial.print("\r\n message[0] is: ");
						Serial.print(message[0],DEC);
						Serial.print("\r\n message[1] is: ");
						Serial.print(message[1],DEC);
						Serial.print("\r\n message[2] is: ");
						Serial.print(message[2],DEC);
						// assumes only one command per packet
						if (message[0] == 0x2) {
								if (message[1] == 0x10) {
										keyLocker.write(map(message[2], 0, 255, 0, 180));
										Serial.print("\r\nMESSAGE wrote to keyLocker\n");
								}
						}

						if (message[0] == 0x1 && message[1] == 0x0) {
								Serial.print("\r\nShackle toggle\n");
								if (shackleCheck) {
										shackleCheck = false;
								} else {
										shackleCheck = true;
								}
						}

						if (message[0] == 0x2 && message[1] == 0x2) {
								Serial.print("\r\nShackle lock\n");
								closeLock();
						}
						if (message[0] == 0x3 && message[1] == 0x3) {
								Serial.print("\r\nShackle unlock\n");
								openLock();
						}

				}
				if (shackleCheck) {

						shackleFeeler = digitalRead(SHACKLE_FEELER);
						if (shackleFeeler == HIGH) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: HIGH\n");
						} else if (shackleFeeler == LOW) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: LOW\n");
						} else {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER: WTF\n");
						}

						if (shackleFeeler != feelerInput) {
								Serial.print("\r\nMESSAGE SHACKLE_FEELER\n");
								message[1] = 0;
								message[2] = shackleFeeler ? 0 : 1;
								acc.write(message, 3);
								feelerInput = shackleFeeler;
						}
				}


		} else {

		}
		/*
		   keyLocker.write(keyLockerValue);
		   if (keyLockerValue == keyMaxValue){
		   keyStepper = -1;
		   }
		   if (keyLockerValue == keyMinValue){
		   keyStepper = 1;
		   }
		   keyLockerValue += keyStepper;
		 */

		delay(10);
}

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
  else{
    Serial.println("calibrating");
    minLockServo = 0;
    maxLockServo = 100;
    keyLocker.write(minLockServo);
    
    delay(1000);
    minAnalogIn = potiRead(50);
    
    delay(1000);
    keyLocker.write(maxLockServo);
    
    delay(1000);
    maxAnalogIn = potiRead(50);


    writeIntToEEPROM(minLockServo, 3);
    writeIntToEEPROM(maxLockServo, 5);
    writeIntToEEPROM(minAnalogIn, 7);
    writeIntToEEPROM(maxAnalogIn, 9);
    
    writeIntToEEPROM(1, 9);
    writeIntToEEPROM(2, 9);
    
    Serial.print("\n minAnalogIn:");
    Serial.print(minAnalogIn,DEC);
    Serial.print("\n maxAnalogIn:");
    Serial.print(maxAnalogIn,DEC);
    Serial.print("\n minLockServo:");
    Serial.print(minLockServo,DEC);
    Serial.print("\n maxLockServo:");
    Serial.print(maxLockServo,DEC);
    Serial.print("\n");

    Serial.println("calibration done");
    return;
    
    Serial.println("we need to calibrate");
    minLockServo = 0;
    maxLockServo = 0;
  }
  keyLocker.write(minLockServo);
  minAnalogIn = analogRead(sensorPin1);
  maxAnalogIn = minAnalogIn;
  int lastPotiChange = minAnalogIn;
  
  int maxStep = 150;
  int stepSize = 5;
  int iterattions = maxStep / stepSize;
  int analogValues[30];
  
  
  for(int k = 0; k * stepSize < 150; k ++){
    int i = k* stepSize; 
    if(!keyLocker.attached()){
      keyLocker.attach(KEY_LOCKER);
    }
    keyLocker.write(i);
//    keyLocker.detach();
    int potiRead = 0;
    {//detached servo
          delay(100);
          Serial.println("Iteration: ");
          Serial.print(i,DEC);    
          //Serial.print("                                                                                                 ");

          for (int j = 0; j < 50; j++){
            int readValue = analogRead(sensorPin1);
            potiRead += readValue;
//            Serial.print(readValue,DEC);
//            Serial.print(" ");
          }
          potiRead /= 50;
          analogValues[k] = potiRead;
    }
    
    Serial.println("");

    Serial.print("reading value from sensor: ");
    Serial.print(potiRead,DEC);
    
    if(potiRead < minAnalogIn){
      minAnalogIn = potiRead;
    }
    if(potiRead > maxAnalogIn){
      maxAnalogIn = potiRead;

    }
    Serial.print("diff beetween this and the last step:");
    Serial.print(lastPotiChange - potiRead,DEC);

    Serial.print(" min:");
    Serial.print(minAnalogIn,DEC);
    Serial.print(" max:");
    Serial.print(maxAnalogIn,DEC);


   if(k > 5){
     int sum = 0;
      sum = abs(analogValues[k] - analogValues[k-1]);
      sum += abs(analogValues[k] - analogValues[k-2]);
      sum += abs(analogValues[k] - analogValues[k-3]);
      sum += abs(analogValues[k] - analogValues[k-4]);
      Serial.print("#####   average is");
      Serial.println(sum,DEC);
    } 
    lastPotiChange = potiRead;
  }
  if(!keyLocker.attached()){
    keyLocker.attach(KEY_LOCKER);
  }

  writeIntToEEPROM(minLockServo, 3);
  writeIntToEEPROM(maxLockServo, 5);
  writeIntToEEPROM(minAnalogIn, 7);
  writeIntToEEPROM(maxAnalogIn, 9);
  
  keyLocker.write(0);
}

void openLock(){
  keyLocker.write(minLockServo);
}
void closeLock(){
    keyLocker.write(maxLockServo);
}

boolean lockIsOpen(){
  int potiValue = potiRead(20);
  if (abs(potiValue - minLockServo) < abs(potiValue - maxLockServo)){
    return true;
  }
  return false;
}

//helper stuff

void writeIntToEEPROM(int value, int EEPROMaddress){
  byte a1 = (value >> 8);
  byte a2 = (value);
  EEPROM.write(a1,EEPROMaddress);
  EEPROM.write(a2,EEPROMaddress+1);
}

int potiRead(int iterations){
  int potiRead = 0;
  for (int j = 0; j < iterations; j++){
    potiRead += analogRead(sensorPin1);
  }
  potiRead /= iterations;
  return potiRead;
}

int readIntFromEEPROM(int EEPROMaddress){
  return EEPROM.read(EEPROMaddress) << 8 | EEPROM.read(EEPROMaddress+1);
}
