#include <PubSubClient.h>
#include <ESP8266WiFi.h>


#define BUT_p 2
#define LED1_p 0


// Settings:
char ssid[]     = "EMLI-TEAM-12"; 
char password[] = "whatever"; 
char MQTTUser[] = "my_user";
char MQTTPass[] = "whatever";

char trigger_id[] = "1";

char serverIP[] = "192.168.10.1"; //The servers IP adress
short serverPort = 1883; //Port used for server

// Topics
char mqttMachineActive[75];
char mqttMachineIn[75];
char mqttMachineOut[75];

// Setup instances 
WiFiClient wificlient;
PubSubClient client(wificlient);

void setup() {
  Serial.begin(115200);
  Serial.println("Serial Started!");
  setupPins();

  connectWIFI();
  setupMQTT();

}

void loop() {
  // put your main code here, to run repeatedly:
  if(!digitalRead(BUT_p)){
    Serial.println("Triggerreddd!");
    postTrigger();
    digitalWrite(LED1_p,true);
    while(!digitalRead(BUT_p)){
      delay(50);
      //Let go of the button...
    }
    digitalWrite(LED1_p,false);
  }
  client.loop();
}
