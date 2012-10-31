Room = require './room'
util = require 'util'

module.exports = class MucHandler
	constructor: ->
		@rooms = {}

	handle: (stanza, res, next) ->
		if not stanza.is('presence') then return next()
		roomId = stanza.from.split("/")[0]
		room = @rooms[roomId]
		if not room then return next()
		switch stanza.attrs.type
			when 'unavailable' then room.unavailableHandler(stanza)
			when 'error' then room.errorHandler(stanza)
			else room.availableHandler(stanza)
		next?()

	addRoom: (roomId) ->
		@rooms[roomId] = new Room(roomId)

	removeRoom: (roomId) ->
		room = @rooms[roomId]
		delete @rooms[roomId]
		room

