User = require "../model/user"

check = require("validator").check

findById = (id, done) ->
	User.find { id: id }, (err, user) ->
		done err, user

findByEmail = (email, done) ->
	User.findOne { email: email }, (err, user) ->
		done err, user

removeById = (userId, done) ->
	User.remove { id: userId}, (err, user) ->
		done err, user

validate = (user) ->
	check(user.username, 'Username must be 1-20 characters long').len(1, 20)
	check(user.password, 'Password must be 5-60 characters long').len(5, 60)

#trouve la liste des cartes de fidélités pas encore imprimées
findAll = (done) ->
	User.find({}).exec (err, data) ->
		done err, data

module.exports =
	findAll: findAll
	findById: findById
	findByEmail: findByEmail
	removeById: removeById
