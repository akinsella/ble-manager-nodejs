passport = require 'passport'

utils = require '../lib/utils'
security = require '../lib/security'

login = passport.authenticate 'local', (req, res) ->
    res.redirect "/"

loginForm = (req, res) =>
	res.redirect "/login.html"

logout = (req, res) =>
	req.logout()
	res.redirect "/login"

# GET /auth/google/callback
#   Use passport.authenticate() as route middleware to authenticate the
#   request.  If authentication fails, the user will be redirected back to the
#   login p
# age.  Otherwise, the primary route function function will be called,
#   which, in this example, will redirect the user to the home page.
authGoogleCallback = (req, res) =>
	res.redirect "/"


module.exports =
	loginForm: loginForm
	login: login
	logout: logout
	authGoogleCallback: authGoogleCallback
