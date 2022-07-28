/**
 *  Configuration file for wiring of smartBraceletsC module to other common 
 *  components needed for proper functioning
 *
 *  @author Kevin Mazzoni
 */

#include "smartBracelets.h"

configuration smartBraceletsAppC {}

implementation {


/****** COMPONENTS *****/

  //Main components
  components MainC, smartBraceletsC as App;
  
  //Communication components
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC;
  
  //Timer components
  components new TimerMilliC() as MilliTimer1;
  components new TimerMilliC() as MilliTimer2;
  components new TimerMilliC() as MilliTimer3;
  
  //Sensing components
  components new FakeSensorC();
  


/****** INTERFACES *****/

  //Boot interface
  App.Boot -> MainC.Boot; 
  
  //Communication interfacces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  
  //Radio control
  App.SplitControl -> ActiveMessageC;
  
  //Timer interfaces
  App.MilliTimer1 -> MilliTimer1;
  App.MilliTimer2 -> MilliTimer2;
  App.MilliTimer3 -> MilliTimer3;
  
  //Packet interfaces
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements -> ActiveMessageC;
  
  //Sensor read
  App.Read -> FakeSensorC;

}

