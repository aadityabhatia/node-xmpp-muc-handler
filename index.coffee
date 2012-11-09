Room = require './room'
util = require 'util'

module.exports = class MucHandler
	constructor: ->
		@rooms = {}

	handle: (stanza, res, next) ->
		roomId = stanza.from.split("/")[0]
		room = @rooms[roomId]
		if not room then return next()

		if stanza.attrs.type is 'error'
			room.errorHandler(stanza)
			return next()

		switch stanza.name
			when 'presence' then @handlePresence room, stanza
			when 'message' then room.messageHandler(stanza)

		next()

	handlePresence: (room, stanza) ->
		switch stanza.attrs.type
			when 'unavailable' then room.unavailableHandler(stanza)
			when 'error' then room.errorHandler(stanza)
			else room.availableHandler(stanza)

	addRoom: (roomId) ->
		@rooms[roomId] = new Room(roomId)

	removeRoom: (roomId) ->
		room = @rooms[roomId]
		delete @rooms[roomId]
		room

