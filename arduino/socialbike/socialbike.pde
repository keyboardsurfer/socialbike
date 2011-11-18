#include <Wire.h>
#include <Servo.h>
#include <EEPROM.h>
#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

#define  KEY_LOCKER     13

#define  SHACKLE_FEELER 42
#define  SHACKLE_OUTPUT 23
#define  servoSensor     1
#define  PASSWORD_EEPROM_ADDR 20
#define  MASTER_KEY_ADDR 30

AndroidAccessory acc("SocialBike",
				"Social Bike Lock",
				"SocialBike Lock",
				"0.1",
				"https://market.android.com/details?id=org.cbase.dev.adkbike",
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

boolean passwordCorrect(int addr, byte a, byte b, byte c, byte d);
boolean passwordCorrect(byte a, byte b, byte c, byte d);

void writePassword(int addr, byte a, byte b, byte c, byte d);
void writePassword(byte a, byte b, byte c, byte d);

//helper methods
void writeIntToEEPROM(int value, int EEPROMaddress);
int readIntFromEEPROM(int EEPROMaddress);
int potiRead(int iterations);

void init_locker()
{
		keyStepper = 1;
		keyMaxValue = 120;
		keyMinValue = 20;
		keyLockerValue = keyMinValue;
		keyLocker.attach(KEY_LOCKER);
		keyLocker.write(keyLockerValue);
}

void init_shackle_feeler()
{
		pinMode(SHACKLE_FEELER, INPUT);
		pinMode(SHACKLE_OUTPUT, OUTPUT);
  digitalWrite(SHACKLE_OUTPUT, LOW);
}

byte feelerInput;
bool shackleCheck = false;

void setup()
{
		Serial.begin(115200);
		Serial.print("\r\nStart Version 24\n");

                if(!passwordCorrect(49, 50, 51, 52)){
                  Serial.print("writing default key in the EEPROM");
                  writePassword(49, 50, 51, 52);
                }
                else{
                  Serial.print("EEPROM seems to have the correct password");
                }
                
                if(!passwordCorrect(MASTER_KEY_ADDR, 0x2, 0x3, 0x4, 0x2)){
                  Serial.print("writing 2343 as master key in the EEPROM");
                  writePassword(MASTER_KEY_ADDR, 0x2, 0x3, 0x4, 0x2);
                }
                else{
                  Serial.print("\nEEPROM seems to have the correct master key");
                }

		init_locker();
		init_shackle_feeler();

                calibrateLock();

		acc.powerOn();
}

void loop()
{
  if (Serial.available() > 0) {
    byte inChar = Serial.read();
      if (inChar == 'l') {
        if (lockIsOpen()){
          Serial.println("\nthe lock is open\n");
        }
        else{
          Serial.println("\nthe lock is closed\n");
        }
      }
      if (inChar == 's') {
        if (shackleIsOpen()){
          Serial.println("\nthe shackle is open\n");
        }
        else{
          Serial.println("\nthe shackle is closed\n");
        }
      }
      else if (inChar == 'o') {
        openLock();
      }
      else if (inChar == 'c') {
        closeLock();
      }
      else if (inChar == 'h') {
        Serial.println("possible commands: [h]elp [o]pen [c]lose [s]hacle status [l]ock status");
      }
  }
  
		byte message[16];

		if (acc.isConnected()) {
				int length = acc.read(message, sizeof(message), 1);
				byte shackleFeeler;

				if (length > 0) {
                                                Serial.print("\r\n acc.read returned: ");
                                                Serial.print(length, DEC);
						Serial.print("\r\n size of message[]: ");
						Serial.print(sizeof(message), DEC);
                                                Serial.print("\r\n");
                                                Serial.print("\r\n Received stuff: ");
						for (int i = 0; i < 16; i++){
                                                  Serial.print(message[i], DEC); Serial.print(" ");
                                                }
                                                Serial.print("\r\n");
						// assumes only one command per packet
						if (message[0] == 0x2) {
						  closeLock();
						}

						if (message[0] == 0x1 && message[1] == 0x0) {
								Serial.print("\r\nShackle toggle\n");
								if (shackleCheck) {
										shackleCheck = false;
								} else {
										shackleCheck = true;
								}
						}

						if (message[0] == 0x2) {
						  Serial.print("\r\nShackle lock\n");
						  closeLock();
                                                  byte answer[3];
                                                  answer[0] = 0x2;
                                                  answer[1] = 0x1;
                                                  answer[2] = 0x0;
                                                  acc.write(answer, 3); 
						}
						if (message[0] == 0x3){
                                                byte answer[3];
                                                answer[0] = 0x3;
                                                  if(passwordCorrect(message[2], message[3], message[4], message[5])){
					            Serial.print("\r\nPin was correct Shackle unlock\n");
						    openLock();
                                                    answer[1] = 0x1;
                                                  }
                                                  else{
                                                    Serial.print("\r\nPin was not correct\n");
                                                    answer[1] = 0x0;
                                                  }
                                                  answer[2] = 0x0;
                                                  acc.write(answer, 3);
						}
						if (message[0] == 0x4) {
								Serial.print("\r\nCheck lock state\n");
								sendLockState(acc);
						}
						if (message[0] == 0x5) {
								Serial.print("\r\nCheck shackle state\n");
								sendShackleState(acc);
						}
                                                if (message[0] == 0x6) {
                                                  byte answer[3];
                                                answer[0] = 0x6;
						  if(passwordCorrect(MASTER_KEY_ADDR, message[2], message[3], message[4], message[5])){
                                                      Serial.print("\r\nMaster key is correct, we´re setting the key\n");
                                                     writePassword(message[6], message[7], message[8], message[9]);
                                                     answer[1] = 0x1;
                                                   }
                                                   else{
                                                     Serial.print("\r\nMaster key is not correct\n");
                                                     answer[1] = 0x0;
                                                   }
                                                  answer[2] = 0x0;
                                                  acc.write(answer, 3);
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
    Serial.println("\ncalibrating");
    minLockServo = 20;
    maxLockServo = 120;
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
  minAnalogIn = analogRead(servoSensor);
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
            int readValue = analogRead(servoSensor);
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
  Serial.print("lockIsOpen");
  //int potiValue = potiRead(servoSensor); //???
  int potiValue = potiRead(20);
  if (abs(potiValue - minLockServo) < abs(potiValue - maxLockServo)){
    Serial.print("\nlockIsOpen: true");
    return true;
  }
    Serial.print("\nlockIsOpen: false");
  return false;
}
boolean shackleIsOpen(){
  Serial.print("\nshackleIsOpen\n");
  digitalWrite(SHACKLE_OUTPUT, HIGH);
  //int potiValue = potiRead(servoSensor); //???
  boolean shackle = !digitalRead(SHACKLE_FEELER);
  //delay(500);
  digitalWrite(SHACKLE_OUTPUT, LOW);
  return shackle;
}

//helper stuff

void writeIntToEEPROM(int value, int EEPROMaddress){
  byte a1 = (value >> 8);
  byte a2 = (value);
  EEPROM.write(EEPROMaddress,a1);
  EEPROM.write(EEPROMaddress+1, a2);
}

int potiRead(int iterations){
  int potiRead = 0;
  for (int j = 0; j < iterations; j++){
    potiRead += analogRead(servoSensor);
  }
  potiRead /= iterations;
  return potiRead;
}

int readIntFromEEPROM(int EEPROMaddress){
  return EEPROM.read(EEPROMaddress) << 8 | EEPROM.read(EEPROMaddress+1);
}

void sendLockState(AndroidAccessory acc) {

    Serial.print("\n\n sendLockState ");

    byte answer[3];
    answer[0]=4;
//    message[1]=lockIsOpen() ? 1 : 0;
    answer[1]=lockIsOpen() ? 0 : 1;
    answer[2]=0;
    acc.write(answer, 3);

}
void sendShackleState(AndroidAccessory acc) {

    Serial.print("\n\n sendShackleState \n");

    byte answer[3];
    answer[0]=5;
    answer[1]=shackleIsOpen();
    answer[2]=0;
    acc.write(answer, 3);

}
boolean passwordCorrect(int addr, byte a, byte b, byte c, byte d){
Serial.print("This is in the EEPROM:\n");
Serial.print(EEPROM.read(addr+0),DEC);       Serial.print(" "); 
Serial.print(EEPROM.read(addr+1),DEC);       Serial.print(" ");
Serial.print(EEPROM.read(addr+2),DEC);       Serial.print(" ");
Serial.print(EEPROM.read(addr+3),DEC);       Serial.print("\n");
return   a == EEPROM.read(addr+0)
      && b == EEPROM.read(addr+1)
      && c == EEPROM.read(addr+2)
      && d == EEPROM.read(addr+3);
}

boolean passwordCorrect(byte a, byte b, byte c, byte d){
   return passwordCorrect(PASSWORD_EEPROM_ADDR, a, b, c, d);
}

void writePassword(int addr, byte a, byte b, byte c, byte d){
  EEPROM.write(addr+0, a);
  EEPROM.write(addr+1, b);
  EEPROM.write(addr+2, c);
  EEPROM.write(addr+3, d);
}
void writePassword(byte a, byte b, byte c, byte d){
    writePassword(PASSWORD_EEPROM_ADDR, a, b, c, d);
}

