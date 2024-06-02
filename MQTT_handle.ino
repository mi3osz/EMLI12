void mqttHandle(){
  //Check whether MQTT client is still connected
  if (!client.connected()) {
    //test whether the wifi connection is lost.
    if(WiFi.status() != WL_CONNECTED){
      Serial.println("Wifi connection was lost. Reconnecting.");
      connectWIFI();
    }
    //delay((keepAlive*1000)+100);
    Serial.println("Might Aswell Reconnect now...");
    reconnect();
  }
  //run client loop.
  client.loop();
}


void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Attempt to connect
    if (client.connect(trigger_id,MQTTUser,MQTTPass,mqttMachineActive,1,0,"DISCONNECTED")) {
      Serial.println("connected");
      mqttConnected(); // Run the connected function once connected.
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}


void callback(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    msg = (msg+(char)payload[i]);
  }
  Serial.println(msg);
  if(!(msg=="")){
    Serial.print("OMG DO STUFF");
  }
}

void postTrigger(){

    char result[50];
    (String("TRIGGER")).toCharArray(result,7);
    client.publish(mqttMachineOut, result);
}

void mqttConnected(){

      client.publish(mqttMachineActive, "STANDBY",true); // Share connection.
      client.subscribe(mqttMachineIn); // Subscribe to the inwards.
}
