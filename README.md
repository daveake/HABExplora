HAB Chase App
====================

Intended for use on phones, this is an Android app that performs the most important functions needed when chasing a balloon:

- Receives GPS location from phone and uploads to Habitat server
- Receives tracker telemetry and uploads to Habitat server
- Shows distance and direction to balloon
- Shows balloon and phone on a map
- Provides driving directions to the balloon
- Uploads received image data (SSDV)
- Support for up to 3 payloads

Currently, the software can receive telemetry from these sources:
 
- LoRa receiver connected via USB (requires USB OTG support)
- Habitat (requires internet connection)

Future versions will include support for these sources:

- LoRa receiver connected via Bluetooth
- Various sources (auto_rx for Sondes, HABDEC for RTTY) connected via WiFi

Other possible future enhancements:

- Support for ad-hoc LoRa settings
- Support for LoRa calling mode
- Support for HABPack format
- LoRa AFC

LoRa Receiver
===========

For this you will need to a suitable LoRa receiver with USB serial connection, for example:

- Uputronics USB LoRa receiver (TBA)
- Adafruit Feather LoRa
- Arduino Mini Pro plus LoRa module plus USB programmer (with FTDI or Prolific chip)

and a USB OTG cable to connect to your phone.

Whichever you choose, it will need to be programmed with this firmware << LINK


Installation
============

Install from the Google Play store or a supplied .APK file.

When you connect the USB receiver, Android will prompt for which app to associate the device with; choose this app so that Android starts it automatically when you connect the receiver.



Configuration
=============

Start the app, then touch the Settings button.  You will then see ....

	
### General Settings ###

### GPS Settings ###

### LoRa Settings ###

Frequency:	This sets the frequency for LoRa module.

Mode: Sets the "mode" for the LoRa module, which is one of:
				
	0 = (normal for telemetry)	Explicit mode, Error coding 4:8, Bandwidth 20.8kHz, SF 11, Low data rate optimize on
	1 = (normal for SSDV) 		Implicit mode, Error coding 4:5, Bandwidth 20.8kHz,  SF 6, Low data rate optimize off
	2 = (normal for repeater)	Explicit mode, Error coding 4:8, Bandwidth 62.5kHz,  SF 8, Low data rate optimize off
	3 = (normal for fast SSDV)	Explicit mode, Error coding 4:6, Bandwidth 250kHz,   SF 7, Low data rate optimize off
	4 = Test mode not for normal use.
	5 = (normal for calling mode)	Explicit mode, Error coding 4:8, Bandwidth 41.7kHz, SF 11, Low data rate optimize off.  Calling mode not currently supported.
	6 =
	7 = (normal for Telnet mode)
				
 

Payloads Screen
===============


Direction Screen
================


Map Screen
==========


Sources Screen
==============


Change History
==============

126/03/2019 - V1.0.1
--------------------

	First Public Release