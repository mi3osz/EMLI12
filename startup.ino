
void setupPins(){
  pinMode(LED1_p, OUTPUT);

  pinMode(BUT_p, INPUT_PULLUP);

  digitalWrite(LED1_p,!true);
  delay(500);
  digitalWrite(LED1_p, !false);
  delay(500);

}

void setTopics() {
  ("remote-trigger/"+String(trigger_id)+"/status").toCharArray(mqttMachineActive,75);
  ("remote-trigger/"+String(trigger_id)+"/in").toCharArray(mqttMachineIn,75);
  ("remote-trigger/"+String(trigger_id)+"/out").toCharArray(mqttMachineOut,75);
}

void setupMQTT(){
  setTopics();
  Serial.println("Connecting to: "+String(serverIP)+"| Port:"+String(serverPort));
  client.setServer(serverIP, serverPort);
  client.setCallback(callback);
  reconnect();
  
}

//-=-=-=-=-=- WIFI Setup -=-=-=-=-=-=-
void connectWIFI(){
  //WiFi.disconnect(true);
  Serial.print("Connecting to network: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  int counter = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    counter++;
    if(counter>=60){ //after 30 seconds timeout - reset board
      Serial.println("No Internet.\nRestarting ESP \nin the 3 seconds.\nLet's hope for internet!");
      delay(3000);
      ESP.restart();
    }
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address set: "); 
  Serial.println(String(WiFi.localIP())); //print LAN IP
}
