var express = require('express');
var app = express();
var uuid = require('node-uuid');
var Pool = require('pg').Pool;

const conString = {
    user: process.env.DBUSER,
    database: process.env.DB,
    password: process.env.DBPASS,
    host: process.env.DBHOST,
    port: process.env.DBPORT,
    ssl: { rejectUnauthorized: false }
};

// Create the pool once, reuse across requests
const pool = new Pool(conString);

app.get('/api/status', function(req, res, next) {
  pool.connect((err, client, release) => {
    if (err) {
      console.error('Error acquiring client', err.stack);
      return next(err);   // let Express error handler respond, don't hang
    }
    client.query('SELECT now() as time', (err, result) => {
      release();
      if (err) {
        console.error('Error executing query', err.stack);
        return next(err);
      }
      res.status(200).send(result.rows);
    });
  });
});