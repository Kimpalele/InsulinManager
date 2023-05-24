//Created by Kim Jogholt on behalf of PiezoMotor

#include "functions.h"
#include <SoftwareSerial.h>

#define RX 1
#define TX 2

SoftwareSerial HM10(RX,TX);

void setup() {
  HM10.begin(115200);
  Serial.begin(115200);

  while (!Serial) {
    ; // wait for serial port to connect.
  }
}

void loop() {
  
  /*
  //For testing purposes when app is unavailable
  String dose = "35";
  distDose(dose.toInt());
  delay(7000);
  reset();
  delay(6000);
  */
  
  
  if(HM10.available()){ //Checks if we got any input

    //Reads the received string and adds it into string to be compared
    String dose = HM10.readString();     
      
    if (dose == "reset"){
        reset();
    } else if (dose.toInt()){
        distDose(dose.toInt());
    } else {
        Serial.println("Something went terribly wrong. . .");
    }
      
    //Sometimes the driver stumbles upon trailing bytes that follows
    //with the command that was given so that it doesn't work.
    //So we flush the serial port continously after every execution
    Serial.flush();
    
  } 
}




