// Import express
let express = require('express');
// Import Body parser
let bodyParser = require('body-parser');

// Initialise the app
let app = express();

//var cors = require('cors');
//var corsOptions = {
//    origin: '*',
//    optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204
//  }
//app.use(cors(corsOptions));

// Import routes
let apiRoutes = require("./apiRoutes");
// Configure bodyparser to handle post requests
app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

// Setup server port
var port = process.env.PORT || 8080;

// Send message for default URL
//app.get('/', (req, res) => res.send('This is Credit Service API.'));

// Use Api routes in the App
//app.use('/ws/pg', apiRoutes);
app.use('/', apiRoutes);
// Launch app to listen to specified port

app.listen(port, function () {
    console.log("Credit Service is listening on port " + port);
});

module.exports = app