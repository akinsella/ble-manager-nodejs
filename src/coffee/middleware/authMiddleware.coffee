passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy
BasicStrategy = require('passport-http').BasicStrategy
ClientPasswordStrategy = require('passport-oauth2-client-password').Strategy
BearerStrategy = require('passport-http-bearer').Strategy

config = require '../conf/config'
User = require '../model/user'
utils = require '../lib/utils'
db = require '../db'

# Use the GoogleStrategy within Passport.
#   Strategies in passport require a `validate` function, which accept
#   credentials (in this case, an OpenID identifier and profile), and invoke a
#   callback with a user object.
GoogleStrategy = new GoogleStrategy({
		returnURL: config.auth.google.callbackUrl,
		realm: config.auth.google.realm,
		stateless: true
	}, (identifier, profile, done) =>
		# asynchronous verification, for effect...
		process.nextTick () =>

			# To keep the example simple, the user's Google profile is returned to
			# represent the logged-in user.  In a typical application, you would want
			# to associate the Google account with a user record in your database,
			# and return that user instead.
			profile.identifier = identifier
			User.findOne { email: profile.emails[0].value }, (err, user) ->
				if (err)
					done(err, null)
				else if (user)
					user.firstName = profile.name.givenName
					user.lastName = profile.name.familyName
					user.gender = profile.gender
					user.googleId = utils.getParameterByName(profile.identifier, "id")
					user.avatarUrl = if profile.photos then profile.photos[0].value else "images/avatar_placeholder.png"
					user.role = if profile.emails[0].value == config.admin.email then "ROLE_ADMIN" else "ROLE_USER"
					user.save (err) ->
						done(err, profile)
				else
					user = new User(
						email:profile.emails[0].value
						firstName: profile.name.givenName
						lastName: profile.name.familyName
						gender: profile.gender
						avatarUrl:  if profile.photos then profile.photos[0].value else "images/avatar_placeholder.png"
						googleId:utils.getParameterByName(profile.identifier, "id")
						role: if profile.emails[0].value == config.admin.email then "ROLE_ADMIN" else "ROLE_USER"
					)
					user.save (err) ->
						done(err, profile)
	)


###
BasicStrategy & ClientPasswordStrategy

These strategies are used to authenticate registered OAuth clients.  They are
employed to protect the `token` endpoint, which consumers use to obtain
access tokens.  The OAuth 2.0 specification suggests that clients use the
HTTP Basic scheme to authenticate.  Use of the client password strategy
allows clients to send the same credentials in the request body (as opposed
to the `Authorization` header).  While this approach is not recommended by
the specification, in practice it is quite common.
###
BasicStrategy = new BasicStrategy((username, password, done) ->
	db.clients.findByClientId username, (err, client) ->
		return done(err)  if err
		return done(null, false)  unless client
		return done(null, false)  unless client.clientSecret is password
		done null, client
)

ClientPasswordStrategy = new ClientPasswordStrategy((clientId, clientSecret, done) ->
	db.clients.findByClientId clientId, (err, client) ->
		return done(err)  if err
		return done(null, false)  unless client
		return done(null, false)  unless client.clientSecret is clientSecret
		done null, client

)

###
BearerStrategy

This strategy is used to authenticate users based on an access token (aka a
bearer token).  The user must have previously authorized a client
application, which is issued an access token to make requests on behalf of
the authorizing user.
###
BearerStrategy = new BearerStrategy((accessToken, done) ->
	db.accessTokens.find accessToken, (err, token) ->
		return done(err)  if err
		return done(null, false)  unless token
		db.users.find token.userID, (err, user) ->
			return done(err)  if err
			return done(null, false)  unless user

			# to keep this example simple, restricted scopes are not implemented,
			# and this is just for illustrative purposes
			info =
				scope: "*"
			done null, user, info


)

module.exports =
	GoogleStrategy: GoogleStrategy
	BasicStrategy: BasicStrategy
	ClientPasswordStrategy: ClientPasswordStrategy
	BearerStrategy: BearerStrategy