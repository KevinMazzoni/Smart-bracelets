/**
 *  Source file for implementation of module smartBraceletsC in which
 *  two motes exchange their keys and...
 *  Node 2 starts 3 seconds later than node 1, this is done in the TunSimulationScript.py file
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Kevin Mazzoni
 */

#include "smartBracelets.h"
#include "Timer.h"

module smartBraceletsC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
    interface Receive;
    interface AMSend;
    interface SplitControl;
    
	//interface for timer
	interface Timer<TMilli> as MilliTimer1;
	interface Timer<TMilli> as MilliTimer2;
	interface Timer<TMilli> as MilliTimer3;
	
    //other interfaces
    interface Packet;
    interface PacketAcknowledgements;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  //Variables
  
  uint8_t counter = 0;
  uint8_t acks = 0;
  
  uint8_t saved_address;
  uint16_t last_x = 0;
  uint16_t last_y = 0;
  uint8_t* key;
  
  uint8_t kinematic;
  uint8_t value_x;
  uint8_t value_y;
  uint8_t value_kinematic;
  
  uint8_t locked = FALSE;
  uint8_t pairing_done = FALSE;
  uint8_t flag_ACK_requested = FALSE;
  
  message_t packet;


  //Functions
  
  void sendPairing();
  void sendPairingDone();
  void sendInfo();
  void fillKeyField(my_msg_t* rcm, char* key);
  bool equalKeys(my_msg_t* rcm, char* secondKey);
  
  
  
  //********************Function to fill the key field of the structure my_msg_t********************//
  
  void fillKeyField(my_msg_t* rcm, char* key){
  
  	//dbg("radio_send", "Entered in fillKeyField()\nkey received: %s\n", key);
  	
  	for(counter = 0; counter < 21; counter ++){
  		rcm -> key[counter] = key[counter];
  		//dbg("radio","Filling key; key[%hu] vale %hu\n", counter, rcm -> key[counter]);
  	}
  	
  	//dbg("radio_send", "key filled!\tkey inserted in rcm -> key: %s\n", rcm -> key);
  	//dbg("radio_send", "key length:\n", strlen(rcm -> key));
  	//dbg("radio_send", "key[19]: %s\n", rcm -> key[19]);
  	
  	return;
  }
  
  
  
  //********************Function to compare two keys********************//
  
  bool equalKeys(my_msg_t* rcm, char* secondKey){
  
  	//dbg("radio_send", "Entered in equalKeys\n\n");
  	
  	bool result = TRUE;
  	
  	//dbg("radio_send", "Entered in equalKeys\n\n");
  	
  	for(counter = 0; counter < 21; counter ++){
  		if(! (rcm -> key[counter] == (uint8_t) secondKey[counter])){
  			result = FALSE;
  			break;
  		}
  	}
  	
  	if(result == TRUE){
  		dbg("radio_send", "the key received is equal to my key\n\n");
  	}
  	else{
  		dbg("radio_send", "the key received is different to my key\n\n");
  	}
  	
  	return result;
  
  }
  
  
  //***************** Send pairing function ********************//
  void sendPairing(){
  
  	my_msg_t* rcm = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
  	
  	//dbg("radio_send", "Entered in sendPairing()\n\n");
  	
  	//dbg("radio","Entered in sendPairing, mote %hu.\n", TOS_NODE_ID);
  	
  	if(rcm == NULL || locked){return;}
  	
  	//dbg("radio","Entered in sendPairing, mote %hu.", TOS_NODE_ID);
  	
  	switch(TOS_NODE_ID){
  	
  		case 1:
  			key = RANDOM_KEY_1;
  			//dbg("radio","key1: %s\n", key);
  			rcm -> msg_type = PAIRING;
  			fillKeyField(rcm, RANDOM_KEY_1);					//This is the parent_1 bracelet
  			dbg("radio","key1 filled successfully");
			rcm -> src_address = 1;
			rcm -> stop_pairing = FALSE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		case 2:
			key = RANDOM_KEY_1;
			//dbg("radio","key1: %s\n", key);
			rcm -> msg_type = PAIRING;			
			fillKeyField(rcm, RANDOM_KEY_1);		//This is the child_1 bracelet
			rcm -> src_address = 2;
			rcm -> stop_pairing = FALSE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		case 3:
			key = RANDOM_KEY_2;
			//dbg("radio","key2: %s\n", key);
			rcm -> msg_type = PAIRING;
  			fillKeyField(rcm, RANDOM_KEY_2);		//This is the parent_2 bracelet
			rcm -> src_address = 3;
			rcm -> stop_pairing = FALSE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		case 4:
			key = RANDOM_KEY_2;
			//dbg("radio","key2: %s\n", key);
			rcm -> msg_type = PAIRING;
			fillKeyField(rcm, RANDOM_KEY_2);		//This is the child_2 bracelet
			rcm -> src_address = 4;
			rcm -> stop_pairing = FALSE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		default:
			dbgerror("pairing", "Mote ID not in range [1...4], Mote ID: %hu not valid, too much motes or too few!\n", TOS_NODE_ID);
			return;
			break;
  	}
  	
  	//if(call PacketAcknowledgements.requestAck(&packet) != SUCCESS){return;}			//The message sent either by the parent or by the child must be ACKed, maybe not useful, since we send broadcast messages, each device in the range should reply to us, we don't know if it is the device we wanted to reach
  	
  	if ((call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t)) == SUCCESS) && !locked ){
		dbg("radio_send", "Sending packet of type PAIRING from Mote %hu in broadcast...\n", TOS_NODE_ID);	
		locked = TRUE;
		dbg_clear("radio_send", " at time %s \n", sim_time_string());
	}
  
  }
  
  
  //***************** Send pairing done function ********************//
  void sendPairingDone(){
  
  	my_msg_t* rcm = (my_msg_t*) call Packet.getPayload(&packet, sizeof(my_msg_t));
  	
  	//dbg("radio_send", "Entered in sendPairingDone()\n\n");
  	
  	if(rcm == NULL || locked){return;}
  	
  	pairing_done = TRUE;
  	
  	dbg("radio","Pairing done between motes %hu and %hu\n", saved_address, TOS_NODE_ID);
  	
  	switch(TOS_NODE_ID){
  	
  		case 1:
  			rcm -> msg_type = PAIRING;
  			fillKeyField(rcm, RANDOM_KEY_1);			//This is the parent_1 bracelet
			rcm -> src_address = 1;
			rcm -> stop_pairing = TRUE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		case 2:
			rcm -> msg_type = PAIRING;			
			fillKeyField(rcm, RANDOM_KEY_1);			//This is the child_1 bracelet
			rcm -> src_address = 2;
			rcm -> stop_pairing = TRUE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		case 3:
			rcm -> msg_type = PAIRING;
  			fillKeyField(rcm, RANDOM_KEY_2);			//This is the parent_2 bracelet
			rcm -> src_address = 3;
			rcm -> stop_pairing = TRUE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		case 4:
			rcm -> msg_type = PAIRING;
			fillKeyField(rcm, RANDOM_KEY_2);			//This is the child_2 bracelet
			rcm -> src_address = 4;
			rcm -> stop_pairing = TRUE;
			rcm -> x_coordinate = 0;
			rcm -> y_coordinate = 0;
			rcm -> kinematic_status = 0;
			break;
		default:
			dbgerror("pairing", "Mote ID not in range [1...4], Mote ID: %hu not valid, too much motes or too few!\n", TOS_NODE_ID);
			return;
			break;
  	}
  	
  	if (call AMSend.send(saved_address, &packet, sizeof(my_msg_t)) == SUCCESS) {
		dbg("radio_send", "Sending packet of type PAIRING_DONE from Mote %hu to Mote %hu...\n", TOS_NODE_ID, saved_address);	
		locked = TRUE;
		dbg_clear("radio_send", " at time %s \n", sim_time_string());
	}
	
  	
  }
  
  
  //***************** Send info function ********************//
  void sendInfo(){
  
  	/* I have to read the position (X,Y) of the mote and the kinematic status
	*  STEPS:
	*  1. Preparing the rcm message
	*  2. Reading first the X coordinate, then the Y coordinate, then retrieve the kinematic status.
	*  3. We set the remaining field, the msg_type, key, src_address, and stop_pairing, according to the node we're on
	*/
	
	my_msg_t* rcm = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	
	//dbg("radio_send", "Entered in sendInfo()\n\n");
	
	if(rcm == NULL){return;}
	
	call Read.read();
	
	rcm -> x_coordinate = value_x;
	rcm -> y_coordinate = value_y;
	
	if(value_kinematic >= 0 && value_kinematic <= 76){					//Case STANDING, P(STANDING) = 0.3
		kinematic = STANDING;
	}
	else if(value_kinematic >= 77 && value_kinematic <= 153){				//Case WALKING, P(WALKING) = 0.3
		kinematic = WALKING;
	}
	else if(value_kinematic >= 154 && value_kinematic <= 230){			//Case RUNNING, P(RUNNING) = 0.3
		kinematic = RUNNING;
	}
	else if(value_kinematic >= 231 && value_kinematic <= 255){ 			//Case FALLING, P(FALLING) = 0.1
		kinematic = FALLING;
	}
	else if(value_kinematic < 0 || value_kinematic > 255){				//Impossible, the random function used generates 16-bit positive integer value...
		dbgerror("value", "Value read from sensor not valid, value: %f\n", value_kinematic);
		return;
	}
	
	rcm -> kinematic_status = kinematic;
	
	if(locked){return;}
	else{
		
		if(TOS_NODE_ID == 2){
			rcm -> msg_type = INFO;
			fillKeyField(rcm, RANDOM_KEY_1);			//Child 1
		 	rcm -> src_address = 2;
		 	rcm -> stop_pairing = TRUE;
		}
		else if(TOS_NODE_ID == 4){
			rcm -> msg_type = INFO;
			fillKeyField(rcm, RANDOM_KEY_2);			//Child 2
		 	rcm -> src_address = 4;
		 	rcm -> stop_pairing = TRUE;
		}
		else{								//Impossible node_ID, error somewhere
			dbgerror("value","value of the mote id reading the sensor not correct. Mote id n. %hu\n", TOS_NODE_ID);
			return;
		}

		if(call PacketAcknowledgements.requestAck(&packet) != SUCCESS){return;}				//These packets require to be ACKed

		if (call AMSend.send(saved_address, &packet, sizeof(my_msg_t)) == SUCCESS) {		//The INFO packet is sent in UNICAST, only to the right parent
			dbg("radio_send", "Sending packet INFO from mote %hu to mote %hu\n", TOS_NODE_ID, saved_address);
			locked = TRUE;																	//Ready to send the packet ot the saved address
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		}
	 
	 }
  }
  

  //***************** Boot interface ********************//
  event void Boot.booted() {
  
	dbg("boot","Application booted.\n");
	key = (uint8_t *) malloc(sizeof(uint8_t) * 21);
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
  
  //dbg("radio_send", "Entered in SplitControl.startDone()\n\n");
    
    if (err == SUCCESS) {
      	dbg("radio","Radio on on node %hu!\n", TOS_NODE_ID);
      	
		call MilliTimer1.startPeriodic(1000);			//Used to re-send broadcast messages for pairing
		
		sendPairing();
    }
    else{
    	dbg("radio","Failed booting radio on node %hu!\n", TOS_NODE_ID);
    }
    
  }
  
  event void SplitControl.stopDone(error_t err){
  	dbg("radio_send", "Entered in SplitControl.stopDone()\n\n");
	dbg("boot", "Radio stopped!\n");
  }

  //***************** MilliTimer 1 interface ********************//
  event void MilliTimer1.fired() {
  
  //dbg("radio_send", "Entered in MilliTimer1.fired()\n\n");
	
	 //counter ++;
	 dbg("timer", "Mote %hu, Timer fired, counter is %hu.\n", TOS_NODE_ID, counter);
	 
	 if(locked){return;}
	 
	 if(pairing_done){
	 	dbg("radio_send", "pairing done\n\n");
	 	call MilliTimer1.stop();
	 	flag_ACK_requested = TRUE;
	 	
	 	if(TOS_NODE_ID == 2 || TOS_NODE_ID == 4){
	 		dbg("radio_send", "starting MilliTimer2\n\n");
	 		call MilliTimer2.startPeriodic(10000);				//If we're in the case of the mote child, we start a timer of 10 seconds...
	 	}
	 	else if(TOS_NODE_ID == 1 || TOS_NODE_ID == 3){
	 		call MilliTimer3.startPeriodic(60000);				//If we're in case of the mote parent, we start a timer of 60 seconds...
	 	}
	 }
	 else{
		sendPairing();	 
	 }
	
  }
  
  
  //***************** MilliTimer 2 interface ********************//
  event void MilliTimer2.fired() {
  
  //dbg("radio_send", "Entered in MilliTimer2.fired()\n\n");
  
	/* Just calling the proper function to send
	*  info to the proper parent mote.
	*/
	
	sendInfo();
	
  }
  
  
  //***************** MilliTimer 3 interface ********************//
  event void MilliTimer3.fired() {
  
  //dbg("radio_send", "Entered in Millitimer3.fired()\n\n");
  
	/* This means the parent mote didn't receive any INFO message
	*  from its child in the last minute, so we launch an alarm
	*/
	
	dbg("ALARM","MISSING ALARM: THE CHILD %hu DIDN'T SEND HIS POSITION IN THE LAST MINUTE TO MOTE %hu!\nThe last position of the children is\n\tX: %hu\n\tY: %hu", saved_address, TOS_NODE_ID, last_x, last_y);
	
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
  
	/* This event is triggered when a message is sent 
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Ckeck if the ACK is requested or not
	 * 3. If it is requested, then check if it arrives or not.
	 * 4. If it doesn't arrive, re-send the packet with function sendInfo()
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	 //dbg("radio_send", "Entered in sendDone()\n\n");
	 
	 if (&packet == buf) {
      locked = FALSE;
      dbg("radio_send", "Packet from Mote %hu sent...\n", TOS_NODE_ID);
      dbg_clear("radio_send", " at time %s \n", sim_time_string());
			
    }
    
    if(flag_ACK_requested && call PacketAcknowledgements.wasAcked(&packet)){
    	acks ++;
    	dbg("ACK", "Packet sent from Mote %hu acknowledged by Mote %hu, acks received at Mote %hu: %hu\n", TOS_NODE_ID, saved_address, TOS_NODE_ID, acks);	
    }
    else if(flag_ACK_requested && !(call PacketAcknowledgements.wasAcked(&packet))){
    	dbgerror("ACK","Packet sent from Mote %hu not acknowledged by Mote %hu, acks received at Mote %hu: %hu\n", 
    	TOS_NODE_ID, saved_address, TOS_NODE_ID, acks);
    	sendInfo();
    }
    
    //dbg("radio_send", "Done sendDone()\n\n");
    
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
  
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is PAIRING
	 * 3. If a PAIRING message is received, check the key 
	 * 4a. If the key matches with the key stored on this mote, the pairing is done, we send back the pairing done message
	 * 4b. If the key doesn't match, we print this fact
	 */
	 
	 //dbg("radio_send", "Entered in receive()\n\n");
	 
	 if(len != sizeof(my_msg_t)){
	 	dbg("radio_rec","Mote %hu received a packet abnormal. Size of this packet: %hu\n", TOS_NODE_ID, len);
	 	return buf;
	 }
	 
	 else{
	 	my_msg_t* rcm = (my_msg_t*) payload;
	 	
	 	
	 	
	 	//MESSAGE RECEIVED PRINTING
	 	
	 	dbg("radio_rec", "Received packet at time %s at mote %hu\n", sim_time_string(), TOS_NODE_ID);
		dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ));
		 
		dbg_clear("radio_pack","\t\t Payload \n" );
		
		//Printing of msg_type
		switch(rcm -> msg_type){
			case(1):
			dbg_clear("radio_pack", "\t\t msg_type: PAIRING\n");
			break;
			case(2):
			dbg_clear("radio_pack", "\t\t msg_type: INFO\n");
			break;
			default:
			dbg_clear("radio_pack", "\t\t msg_type not recognized, unexpected error. Value: %hhu \n", rcm -> msg_type);
			break;
		}
		
		//Printing of the key
		dbg_clear("radio_pack", "\t\t key: %s \n", rcm -> key);
		
		//Printing of src_address
		dbg_clear("radio_pack", "\t\t src_address: %hhu \n", rcm -> src_address);
		
		//Printing of stop_pairing
		switch(rcm -> stop_pairing){
			case(0):
			dbg_clear("radio_pack", "\t\t stop_pairing: FALSE\n");
			break;
			case(1):
			dbg_clear("radio_pack", "\t\t stop_pairing: TRUE\n");
			break;
			default:
			dbg_clear("radio_pack", "\t\t stop_pairing not recognized, unexpected error. Value: %hhu \n", rcm -> stop_pairing);
			break;
		}
		
		//Printing of x_coordinate
		dbg_clear("radio_pack", "\t\t x_coordinate: %hhu \n", rcm -> x_coordinate);
		
		//Printing of y_coordinate
		dbg_clear("radio_pack", "\t\t y_coordinate: %hhu \n", rcm -> y_coordinate);
		
		//Printing of kinematic_status
		switch(rcm -> kinematic_status){
			case(1):
			dbg_clear("radio_pack", "\t\t kinematic_status: STANDING \n");
			break;
			case(2):
			dbg_clear("radio_pack", "\t\t kinematic_status: WALKING \n");
			break;
			case(3):
			dbg_clear("radio_pack", "\t\t kinematic_status: RUNNING \n");
			break;
			case(4):
			dbg_clear("radio_pack", "\t\t kinematic_status: FALLING \n");
			break;
			default:
			dbg_clear("radio_pack", "\t\t kinematic_status not recognized, unexpected error. Value: %hhu \n", rcm -> kinematic_status);
			break;
		}
		
		
		
		//MESSAGE ANALYSIS AND ACTIONS
		 
		if(rcm -> msg_type == PAIRING){						//This means the receives a pairing message
			if(TOS_NODE_ID == 1 || TOS_NODE_ID == 2){
				if(equalKeys(rcm, RANDOM_KEY_1)){
					saved_address = rcm -> src_address;
					if(rcm -> stop_pairing){
						pairing_done = TRUE;
						dbg("radio", "Pairing done succesfully between mote %hu and mote %hu!\n", rcm -> src_address, TOS_NODE_ID);
						return buf;
					}
					else{
						dbg("radio", "Sending pairing done between mote %hu and mote %hu!\n", rcm -> src_address, TOS_NODE_ID);
						sendPairingDone();
						return buf;
					}
				}
				else{
					dbgerror("radio_pack","The key received from Mote %hu doesn't match the key stored in Mote %hu\n", rcm -> src_address, TOS_NODE_ID);
					return buf;
				}
			}
			else if(TOS_NODE_ID == 3 || TOS_NODE_ID == 4){
				if(equalKeys(rcm, RANDOM_KEY_2)){
					saved_address = rcm -> src_address;
					if(rcm -> stop_pairing){
						pairing_done = TRUE;
						return buf;
					}
					else{
						sendPairingDone();
						return buf;
					}
				}
				else{
					dbgerror("radio_pack","The key received from Mote %hu doesn't match the key stored in Mote %hu\n", rcm -> src_address, TOS_NODE_ID);
					return buf;
				}
			}
			else{
				dbgerror("radio_pack", "Node ID not in range [1...4], not valid! Node ID: %hu\n", TOS_NODE_ID);
				return buf;
			}
		}
		
		else if(rcm -> msg_type == INFO){							//LAST PART (3RD FEATURE) FROM HERE...
		
			last_x = rcm -> x_coordinate;
			last_y = rcm -> y_coordinate;
		
			if(rcm -> kinematic_status == FALLING){
				dbg("ALARM","FALL ALARM: THE CHILD %hu FELL!, the position of the children is\n\tX: %hu\n\tY: %hu\n",
				rcm -> src_address, last_x, last_y );
			}
			
			call MilliTimer3.stop();
			call MilliTimer3.startPeriodic(60000);
			
			return buf;
		}
		 
		return buf;
	 
	 }

  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
  
	/* This event is triggered when the fake sensor finishes to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Set the read_value (global variable) to the value provided by the sensor
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	 
	 //dbg("radio_send", "Entered in readDone()\n\n");
	 
	 
	 value_x = (uint8_t) ((data & 0000000011111111) >> 8);
	 value_y = (uint8_t) (data % 256);								//The 3 values are obtained by making bit shifts and sum values...
	 value_kinematic = (uint8_t) ((value_x + value_y) % 256);
	 
	 //dbg("value","value read done, value: %hu\n", data);
	
  }
	
}

