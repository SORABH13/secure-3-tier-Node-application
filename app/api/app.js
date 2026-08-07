var express = require('express');
var app = express();
var Pool = require('pg').Pool;

const conString = {
    user: process.env.DBUSER,
    database: process.env.DB,
    password: process.env.DBPASS,
    host: process.env.DBHOST,
    port: process.env.DBPORT,
    // RDS requires SSL, so it's on by default; local docker-compose Postgres
    // doesn't speak SSL, so it sets DBSSL=false.
    ssl: process.env.DBSSL === 'false' ? false : { rejectUnauthorized: false }
};

// Create the pool once, reuse across requests
const pool = new Pool(conString);

app.get('/api/status', function(req, res, next) {
  pool.connect((err, client, release) => {
    if (err) {
      console.error('Error acquiring client', err.stack);
      return next(err);
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

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.json({
      message: err.message,
      error: err
    });
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
  res.status(err.status || 500);
  res.json({
    message: err.message,
    error: {}
  });
});

module.exports = app;