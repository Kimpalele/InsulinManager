//Created by Kim Jogholt on behalf of PiezoMotor

int stepTot = 0;
String command = "";

//Used to convert the amount of insulin-units given, into steps.
//1 Unit of insulin equals 116 motor steps with the current syringe.
void convertDoseToStep(int dose){
  int step = dose * 116;
  stepTot += step;
}

//Dynamic function that enables us to apply the amount of 
//steps that the motor should take, into a working command.
//Example would be X1T500; Which would then instruct 
//the motor to take 500 index steps forward
void convertStepToString(){
  char newString[20];
  sprintf(newString, "X1T%i;",stepTot);
  command = newString;
  command.trim();
}

void distDose(int dose){
  
  //Basically just takes the string that comes out of
  //convertStepToString() and sends it char by char
  //to the driver
  convertDoseToStep(dose);
  convertStepToString();

  for (int i = 0; i < command.length(); i++){
    Serial.write(command[i]);
  }
}


void reset(){

  //Sending a stop command if the motor were to still
  //be in motion, then sets the motor into index search
  //mode, afterwards just sends the motor backwards until
  //it finds the quadrature index on the drive shaft and stops.
  stepTot = 0;
  Serial.write("X1S;");
  delay(50);
  Serial.write("X1N4;");
  delay(50);
  Serial.write("X1I-10000,0,400;");
  delay(50);

}
