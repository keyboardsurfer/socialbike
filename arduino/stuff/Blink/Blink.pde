/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */

void setup() {                
Serial.print("SETUP");
  // initialize the digital pin as an output.
  // Pin 13 has an LED connected on most Arduino boards:
  pinMode(12, OUTPUT);   
  pinMode(0, OUTPUT);   
  
}

void loop() {
//  digitalWrite(12, HIGH);   // set the LED on
//  delay(50);              // wait for a second
//  digitalWrite(12, LOW);    // set the LED off
//  delay(200);              // wait for a second
//    digitalWrite(12, HIGH);   // set the LED on
//  delay(150);              // wait for a second
//  digitalWrite(12, LOW);    // set the LED off
//  delay(250);  
//  
  
  analogWrite(0, 10);
}


