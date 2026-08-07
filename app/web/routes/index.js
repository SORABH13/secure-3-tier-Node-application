var express = require('express');
var router = express.Router();
var crypto = require('crypto');

var api_url = process.env.API_HOST + '/api/status';

/* GET home page. */
router.get('/', async function(req, res, next) {
    try {
        const response = await fetch(api_url);
        if (!response.ok) {
            return res.status(500).send('error running request to ' + api_url);
        }
        const body = await response.json();
        res.render('index', {
            title: '3tier App',
            request_uuid: crypto.randomUUID(),
            time: body[0].time
        });
    } catch {
        return res.status(500).send('error running request to ' + api_url);
    }
});

module.exports = router;
