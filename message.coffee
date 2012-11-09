module.exports = class Message
	constructor: (opts) ->
		return if typeof opts isnt 'object'
		for key, value of object
			this[key] = value

