/*
  Serial RGB controller
 
 Reads a serial input string looking for three comma-separated
 integers with a newline at the end. Values should be between 
 0 and 255. The sketch uses those values to set the color 
 of an RGB LED attached to pins 9 - 11.
 
 The circuit:
 * Common-anode RGB LED cathodes attached to pins 9 - 11
 * LED anode connected to pin 13
 
 To turn on any given channel, set the pin LOW.  
 To turn off, set the pin HIGH. The higher the analogWrite level,
 the lower the brightness.
 
 created 29 Nov 2010
 by Tom Igoe
 
 This example code is in the public domain. 
 */

#include <EEPROM.h>

String inString = "";    // string to hold input
int eepromStart = 8;

void setup() {
  // Initialize serial communications:
  Serial.begin(9600);

  digitalWrite(13, HIGH);
}

void loop() {
  int inChar;

  // Read serial input:
  if (Serial.available() > 0) {
    inChar = Serial.read();
  }

  if (isDigit(inChar)) {
    // convert the incoming byte to a char 
    // and add it to the string:
    inString += (char)inChar; 
    Serial.print(inString);
    Serial.println("is the string you´e about to write");
  }

  if (inChar == 'r') {
    Serial.println("this is in the EEPROM:");
    char value;
    int eepromAdr = eepromStart; 
    do{
      value = EEPROM.read(eepromAdr++);
      Serial.print(value);
    }while(value != '\n');
    Serial.println("EOM");
  }

  if (inChar == 'w') {
  Serial.println("writing to the EEPROM now!!");
  int eepromAdr = eepromStart; 
  int stringLength = inString.length();
      for (int i = 0;i< stringLength;i++){
        EEPROM.write(eepromAdr++, inString[i]);
      }
      EEPROM.write(eepromAdr, '\n');
      inString = "";
      Serial.println("did write to the EEPROM");
  }

}










