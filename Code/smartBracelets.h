/**
 *  @author Kevin Mazzoni
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg INFO
typedef nx_struct my_msg {
  	nx_uint8_t msg_type;
  	nx_uint8_t key[21];
  	nx_uint8_t stop_pairing;
	nx_uint8_t src_address;
	nx_uint8_t x_coordinate;
	nx_uint8_t y_coordinate;
	nx_uint8_t kinematic_status;
} my_msg_t;

#define PAIRING 1
#define INFO 2

#define MOTE1 1
#define MOTE2 2
#define MOTE3 3
#define MOTE4 4

#define RANDOM_KEY_1 "Avser242bmdGJKEB2J7b"
#define RANDOM_KEY_2 "HFdNkJGB432jnGE89W1m"

#define STANDING 1
#define WALKING 2
#define RUNNING 3
#define FALLING 4

enum{
AM_MY_MSG = 6,
};

#endif
