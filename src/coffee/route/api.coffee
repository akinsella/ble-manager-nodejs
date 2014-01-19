
informations = (req, res) ->
    res.json { minApiVersion: "1" }

module.exports =
    informations: informations
