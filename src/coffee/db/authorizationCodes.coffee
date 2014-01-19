AuthorizationCode = require "../model/authorizationCode"

find = (code, done) ->
	AuthorizationCode.find { code: code }, (err, authorizationCode) ->
		if (err)
			done err, authorizationCode

save = (code, clientID, redirectURI, userID, done) ->
	authorizationCode = new AuthorizationCode({
		clientID: clientID,
		redirectURI: redirectURI,
		userID: userID
	})

	authorizationCode.save (err) ->
		done err, authorizationCode

module.exports =
	find: find
	save:save