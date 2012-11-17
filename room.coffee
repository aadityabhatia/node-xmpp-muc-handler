events = require 'events'
util = require 'util'
User = require './user'

module.exports = class Room extends events.EventEmitter
	constructor: (@roomId) ->
		events.EventEmitter.call(this)
		@roster = {}

	errorHandler: (stanza) ->
		this.emit 'err',
			error: stanza.getChild('error').getText()
			stanza: stanza

	messageHandler: (stanza) ->
		nick = stanza.from.split("/")[1]
		bodyElement = stanza.getChild('body')
		if not bodyElement
			@subject = stanza.getChild('subject')?.getText()
			return if not @subject
			@emit 'subject',
				subject: @subject
				nick: nick
			return

		if stanza.attrs.type is 'chat'
			@emit 'privateMessage',
				to: stanza.attrs.to
				nick: nick
				text: bodyElement.getText()
			return

		@emit 'groupMessage',
			to: stanza.attrs.to
			nick: nick
			text: bodyElement.getText()
			delay: stanza.getChild('delay')?.attrs.stamp

	availableHandler: (stanza) ->
		nick = stanza.from.split("/")[1]
		statusElems = stanza.getChild('x')?.getChildren('status')
		statusCodes = if statusElems then (parseInt(s.attrs.code) for s in statusElems) else []
		selfPresence = statusCodes.indexOf(110) >= 0

		# if nick isn't already on the roster, add it and announce the arrival
		if nick not of @roster
			@roster[nick] = new User(stanza)
			if not selfPresence and @joined
				this.emit 'joined', @roster[nick]
		else
			this.emit 'status', @roster[nick].update(stanza)

		if selfPresence
			@nick = nick

		# this happens at the end of each join
		if selfPresence and not @joined
			@joined = true
			this.emit 'rosterReady', @roster[nick]

	unavailableHandler: (stanza) ->
		nick = stanza.from.split("/")[1]
		statusElems = stanza.getChild('x')?.getChildren('status')
		statusCodes = if statusElems then (parseInt(s.attrs.code) for s in statusElems) else []
		selfPresence = statusCodes.indexOf(110) >= 0

		if statusCodes.indexOf(307) >= 0
			if selfPresence then @joined = false
			delete @roster[nick]
			this.emit 'kicked',
				nick: nick
				reason: stanza.getChild('x')?.getChild('item')?.getChild('reason')?.getText()
				self: selfPresence
			return

		if statusCodes.indexOf(301) >= 0
			if selfPresence then @joined = false
			delete @roster[nick]
			this.emit 'banned',
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
				nick: nick
				newNick: newNick
				self: selfPresence
			return

		status = Strophe.getText(statusElems[0]) if statusElems.length > 0
		if selfPresence then @joined = false
		delete @roster[nick]
		this.emit 'parted',
			nick: nick
			status: status or ""
			self: selfPresence

