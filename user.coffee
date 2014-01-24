module.exports = class User
	constructor: (stanza) ->
		@update(stanza)

	update: (stanza) ->
		room = stanza.from.split("/")[0]
		nick = stanza.from.split("/")[1]
		@show = stanza.getChild('show')?.getText() or 'online'
		@status = stanza.getChild('status')?.getText()
		@priority = parseInt(stanza.getChild('priority')?.getText())

		for x in stanza.getChildren('x')
			for item in x.getChildren('item')
				@affiliation ?= item.attrs.affiliation
				@role ?= item.attrs.role
				@jid ?= item.attrs.jid

		this

#  vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
