module.exports = class User
	constructor: (stanza) ->
		@update(stanza)

	update: (stanza) ->
		room = stanza.from.split("/")[0]
		nick = stanza.from.split("/")[1]
		@show = stanza.getChild('show')?.getText() or 'online'
		@status = stanza.getChild('status')?.getText()
		@priority = parseInt(stanza.getChild('priority')?.getText())

		item = stanza.getChild('x')?.getChild('item')
		if item
			@affiliation = item.attrs.affiliation
			@role = item.attrs.role
			@jid = item.attrs.jid

		this

