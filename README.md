# XMPP MUC Eventer
## event emitting handler for XMPP MUCs

xmpp-muc-handler is an event-emitting handler that processes message and presence stanzas from specified MUCs, maintains a roster, and emits events when activity takes place. It can be used as a middleware for [junction](https://github.com/jaredhanson/junction/#readme) XMPP framework.

## Installation

	npm install xmpp-muc-handler

## Usage
```
MucHandler = require 'xmpp-muc-handler'
mucHandler = new MucHandler()
app.use junction.presenceParser()
app.use junction.messageParser()
app.use mucHandler

connection = client.connect(xmppOptions).on 'online', ->
	room = mucHandler.addRoom bareMucJid
	room.on 'rosterReady', (data) ->
		util.log "Roster: " + JSON.stringify @roster
	room.on 'joined', (data) ->
		util.log "Joined: " + data.nick
	room.on 'parted', (data) ->
		util.log "Parted: " + data.nick
	room.on 'nickChange', (data) ->
		util.log "NickChange: #{data.nick} to #{data.newNick}"
```
## License

	Copyright 2012 Aaditya Bhatia

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

