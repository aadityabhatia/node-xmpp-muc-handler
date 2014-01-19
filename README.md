# XMPP MUC Handler
## event-based API for XMPP Multi-User Chats

xmpp-muc-handler provides a simple event-based API to access [XMPP Multi-User Chats](http://xmpp.org/extensions/xep-0045.html). It processes message and presence stanzas from MUCs, maintains rosters, and emits events for any message or presence stanza received. It can be used as a middleware for [junction](https://github.com/jaredhanson/junction/#readme) XMPP framework.

## Installation

	npm install xmpp-muc-handler

## Usage
```
var MucHandler = require('xmpp-muc-handler');
var junction = require('junction');
var mucHandler = new MucHandler();

var client = junction();
client.use(junction.presenceParser());
client.use(junction.messageParser());
client.use(mucHandler);

var xmppOptions = {
	type: 'client',
	jid: "bot@example.com",
	password: "safe"
};

var roomId = "test@example.com"

var connection = client.connect(xmppOptions).on('online', function() {

	this.send(new junction.elements.Presence(roomId + "/BotTest"));
	var room = mucHandler.addRoom(roomId);

	room.on('rosterReady', function(data) {
		console.log("Roster: " + JSON.stringify(this.roster));
	});

	room.on('subject', function(data) {
		console.log("Subject: " + data.subject);
	});

	room.on('groupMessage', function(data) {
		console.log("<" + data.nick + "> " + data.text);
	});

	room.on('joined', function(data) {
		console.log("Joined: " + data.nick);
	});

	room.on('parted', function(data) {
		console.log("Parted: " + data.nick);
	});

	room.on('nickChange', function(data) {
		console.log("NickChange: " + data.nick + " to " + data.newNick);
	});
});
```
## License

	Copyright 2014 Aaditya Bhatia

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

