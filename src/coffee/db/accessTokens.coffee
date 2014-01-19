AccessToken = require "../model/accessToken"

find = (token, done) ->
	AccessToken.find { token: token }, (err, accessToken) ->
		done err, accessToken

save = (token, userID, clientID, done) ->
	accessToken = new AccessToken({
		userID: userID,
		clientID: clientID
	})

	accessToken.save (err) ->
		done err, accessToken

module.exports =
	find: find
	save: save