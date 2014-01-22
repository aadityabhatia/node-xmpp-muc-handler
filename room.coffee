events = require 'events'
util = require 'util'
junction = require 'junction'
Message = junction.elements.Message
Presence = junction.elements.Presence
Iq = junction.elements.IQ

User = require './user'

module.exports = class Room extends events.EventEmitter
	constructor: (@roomId) ->
		events.EventEmitter.call(this)
		@roster = {}
		@jids = {}

	updateJids: () ->
		temp = {}
		for nick, user of @roster
			if user.jid
				jid = user.jid.split("/",1)[0]
				if jid not of temp
					temp[jid] = user
		@jids = temp

	sendGroup: (message) ->
		return if not @connection
		msg = new Message(@roomId, 'groupchat')
		msg.c('body', {}).t(message)
		@connection.send msg

	sendPrivate: (nick, message) ->
		return if not @connection
		msg = new Message(@roomId + '/' + nick, 'chat')
		msg.c('body', {}).t(message)
		@connection.send msg

	setAffiliation: (nick, affiliation) ->
		return if not @connection
		return if nick not of @roster
		return if ['none', 'member', 'admin', 'owner'].indexOf(affiliation) < 0
		iq = new Iq(@roomId, 'set')
		iq.c('query', {xmlns: 'http://jabber.org/protocol/muc#admin'}).c 'item',
			jid: @roster[nick].jid.split('/')[0]
			affiliation: affiliation
		@connection.send iq

	setRole: (nick, role) ->
		return if not @connection
		return if nick not of @roster
		return if ['none', 'visitor', 'participant', 'moderator'].indexOf(role) < 0
		iq = new Iq(@roomId, 'set')
		iq.c('query', {xmlns: 'http://jabber.org/protocol/muc#admin'}).c 'item',
			nick: nick
			role: role
		@connection.send iq

	part: (message) ->
		return if not @connection
		presence = new Presence(@roomId, 'unavailable')
		if message
			presence.c('status', {}).t(message)
		@connection.send presence

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
			user = new User(stanza)
			user.nick = nick
			@roster[nick] = user
			if user.jid
				jid = user.jid.split("/",1)[0]
				if jid not of @jids
					@jids[jid] = user
			if not selfPresence and @connection
				this.emit 'joined', @roster[nick]
		else
			this.emit 'status', @roster[nick].update(stanza)

		if selfPresence
			@nick = nick

		# this happens at the end of each join
		if selfPresence and not @connection
			@connection = stanza.connection
			this.emit 'rosterReady', @roster[nick]

	unavailableHandler: (stanza) ->
		nick = stanza.from.split("/")[1]
		statusElems = stanza.getChild('x')?.getChildren('status')
		statusCodes = if statusElems then (parseInt(s.attrs.code) for s in statusElems) else []
		selfPresence = statusCodes.indexOf(110) >= 0

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

		if selfPresence then delete @connection

		if statusCodes.indexOf(307) >= 0
			delete @roster[nick]
			this.emit 'kicked',
				nick: nick
				reason: stanza.getChild('x')?.getChild('item')?.getChild('reason')?.getText()
				self: selfPresence
			return

		if statusCodes.indexOf(301) >= 0
			delete @roster[nick]
			this.emit 'banned',
				nick: nick
				reason: stanza.getChild('x')?.getChild('item')?.getChild('reason')?.getText()
				self: selfPresence
			return

		status = statusElems[0].getText() if statusElems.length > 0
		jid = @roster[nick].jid
		delete @roster[nick]
		if jid
			@updateJids()
		this.emit 'parted',
			nick: nick
			jid: jid
			status: status or ""
			self: selfPresence

#  vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
