# InsulinManager
On behalf of PiezoMotor I have created a controller system for a Piezo electric motor using ESP32-C, HM10 bluetooth module, MAX485 (ttl to rs485 converter) and an iOS Application to send commands from. I did this during my LIA-period at Nackademin as a Internet of Things Developer student.

The basic idea was to see if it was possible to make a simple demo for an insulinpump that displayed to preciseness in one of PiezoMotors motors. For this project I've used PiezoLEGS LL06 as a demo product. 

The workflow of the project goes like this: 
1. The user sends the amount of insulin units they'd like distributed, using the phone application.
2. The application then sends the doseage as a string via bluetooth to the HM-10 module.
3. The HM-10 receives the data and sends it serially to the ESP32-C3.
4. The ESP receives the data as a string and then takes the amount of units and converts it into a command for the driver.
5. The ESP sends the data serially, character by character, to the max485 converter.
6. The driver circuit for the motor is communicating via RS485, hence the max485 converter.
7. The max485 converts our ttl signal into rs485 and transfers it to the driver circuit which in turn tells the motor how many steps it should take forward.

There is also a reset button in the app which resets the motor position.

There are also comments in the code which explains why we take a certain amount of steps depending on the amount of insulin units that was input. Currently we take 116 encoder steps per insulin units because of the measurement on the syringe currently in use. Comments also explain the conversion between units into steps and explain what command we use for the driver.

Here's a flowchart of the project, the cloud solution is crossed over because there wasn't enough time for me to complete it.
![NewFlowchart](https://github.com/Kimpalele/InsulinManager/assets/22542852/0b06fee1-a9f3-4da1-ae2f-c272f2281074)

Here's the current wiring diagram for the hardware:
![Flowchart-InsulinManager](https://github.com/Kimpalele/InsulinManager/assets/22542852/fda66e2c-3d12-4f81-8774-070e7e9a6c83)

Also here are some pictures of the hardware in its raw form, the box to contain all of this hasn't been printed yet, only the box for the syringe and motor.
![FullSizeRender](https://github.com/Kimpalele/InsulinManager/assets/22542852/76c54663-b869-4ed6-9191-c716e1cab2e0)

And lastly a picture of the app and the 3d printed design for the motor/syringe.
![unnamed](https://github.com/Kimpalele/InsulinManager/assets/22542852/21a91809-4fd4-4aae-b474-202513514d7a)
<img width="368" alt="Syringebox" src="https://github.com/Kimpalele/InsulinManager/assets/22542852/3b9cc62e-a65f-4d1d-8cd0-f1c375aaef80">![IMG-7309](https://github.com/Kimpalele/InsulinManager/assets/22542852/84ff6afa-9763-4e1e-b5f7-3d553d54a7de)
![IMG-7308](https://github.com/Kimpalele/InsulinManager/assets/22542852/d8dd47ea-7457-4a7f-83ee-13bc73894433)


