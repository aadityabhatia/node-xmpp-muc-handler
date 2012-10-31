events = require 'events'
util = require 'util'
User = require './user'

module.exports = class Room extends events.EventEmitter
	constructor: (@roomId) ->
		events.EventEmitter.call(this)
		@roster = {}

	errorHandler: (stanza) ->
		this.emit 'err', stanza: stanza

	availableHandler: (stanza) ->
		room = stanza.from.split("/")[0]
		nick = stanza.from.split("/")[1]
		statusElems = stanza.getChild('x')?.getChildren('status')
		statusCodes = if statusElems then (parseInt(s.attrs.code) for s in statusElems) else []
		selfPresence = statusCodes.indexOf(110) >= 0

		# if nick isn't already on the roster, add it and announce the arrival
		if nick not of @roster
			@roster[nick] = new User(nick)
			if not selfPresence and @joined
				this.emit 'joined',
					room: room
					nick: nick
		else
			this.emit 'status',
				show: stanza.show
				status: stanza.status

		if selfPresence
			@nick = nick

		# this happens at the end of each join
		if selfPresence and not @joined
			@joined = true
			this.emit 'rosterReady',
				room: room
				nick: nick

	unavailableHandler: (stanza) ->
		room = stanza.from.split("/")[0]
		nick = stanza.from.split("/")[1]
		statusElems = stanza.getChild('x')?.getChildren('status')
		statusCodes = if statusElems then (parseInt(s.attrs.code) for s in statusElems) else []
		selfPresence = statusCodes.indexOf(110) >= 0

		if statusCodes.indexOf(307) >= 0
			if selfPresence then @joined = false
			delete @roster[nick]
			this.emit 'kicked',
				room: room
				nick: nick
				reason: stanza.getChild('x')?.getChild('item')?.getChild('reason')?.getText()
				self: selfPresence
			return

		if statusCodes.indexOf(301) >= 0
			if selfPresence then @joined = false
			delete @roster[nick]
			this.emit 'banned',
				room: room
				nick: nick
				reason: stanza.getChild('x')?.getChild('item')?.getChild('reason')?.getText()
				self: selfPresence
			return

		if statusCodes.indexOf(303) >= 0
			newNick = stanza.getChild('x')?.getChild('item')?.attrs.nick
			if not newNick
				throw new Error "New nick not found in stanza: #{stanza.toString()}"
			@roster[newNick] = @roster[nick]
			delete @roster[nick]
			this.emit 'nickChange',
				room: room
				nick: nick
				newNick: newNick
				self: selfPresence
			return

		status = Strophe.getText(statusElems[0]) if statusElems.length > 0
		if selfPresence then @joined = false
		delete @roster[nick]
		this.emit 'parted',
			room: room
			nick: nick
			status: status or ""
			self: selfPresence

