#include <Servo.h>

/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */

Servo myservo;

void setup() {   
  
Serial.print("SETUP");
  // initialize the digital pin as an output.
  // Pin 13 has an LED connected on most Arduino boards:
//  pinMode(12, OUTPUT);   
  pinMode(3, OUTPUT);   

myservo.attach(3);  
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

//  for(int pos = 0; pos < 180; pos += 20)  // goes from 0 degrees to 180 degrees
//  {                                  // in steps of 1 degree
//    myservo.write(pos);              // tell servo to go to position in variable 'pos'
//    delay(150);                       // waits 15ms for the servo to reach the position
//  }

}


