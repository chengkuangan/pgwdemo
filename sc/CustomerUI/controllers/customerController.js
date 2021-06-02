const express = require("express"),
  path = require("path");
const app = express();
const axios = require("axios");
const prometheus = require("../lib/prometheus");
const logger = require("../lib/logger");

//setup our app to use handlebars.js for templating
app.set("view engine", "hbs");
app.set("views", path.join(__dirname, "views"));

// --- instantiate Keycloak admin client
const AdminClient = require("../lib/adminClient");

var customerAPI_URL =
  process.env.CUSTOMER_API_URL || "http://localhost:8083/ws/pg/customer";
var creditAPI_URL =
  process.env.CREDIT_API_URL || "http://localhost:8084/ws/pg/credits";
var rhsso_URL = process.env.RHSSO_URL || "http://localhost:8080";
var paymentHistory_URL = process.env.PAYMENT_HISTORY_URL || "http://localhost:8080/payments";

let adminClient = new AdminClient({
  realm: "PaymentGateway",
  serverUrl: rhsso_URL,
  resource: "CustomerAccount",
  adminLogin: "pg_admin",
  adminPassword: "password",
});

var customer;
/*
const index_histogram = prometheus.histogram(
  "pgw_customerui:index_duration",
  "Duration of Index HTTP requests in ms",
  ["method", "status_code"],
  [0.1, 5, 15, 50, 100, 500]
);
*/

const transfer_histogram = prometheus.histogram(
  "pgw_customerui:transfer_duration",
  "Duration of Transfer HTTP requests in ms",
  ["method", "status_code"],
  [0.1, 5, 15, 50, 100, 500]
);

// Display index page.
exports.index = function (req, res) {
  //customer = {"accountId": "20191029-MY-123456789", "balance": 120.50, "name": "John Doe"};
  //res.render("index", { customer: customer});
  //return;
  try{
    // retrieve the current login username
    let currentUsername = req.kauth.grant.access_token.content.preferred_username;
    
    // get the accountId from the keycloak user custom attributes
    adminClient.getUser(
      currentUsername,
      function (user) {
        let accountId = user.attributes.accountId[0];
        logger.debug("accountId: " + accountId);
        logger.debug("customerAPI_URL: " + customerAPI_URL);
        axios
          .get(customerAPI_URL + "/" + accountId)
          .then((response) => {
            customer = response.data[0];
            logger.debug("customer: " + customer);
            logger.debug("customer.accountId: " + customer.accountId);
            logger.debug("customer.balance: " + customer.balance);
            res.render("index", { customer: customer });
            //end({ method: req.method, status_code: 200 });
          })
          .catch((error) => {
            logger.error("Error: " + error);
            res.render("index", { "status": "error", "error": "Error retrieving account balance" });
            //end({ method: req.method, status_code: 500 });
          });
      },
      function (error) {
        logger.error("Error: " + error);
        res.render("index", { "status": "error", "error": "Error retrieving account balance" });
        //end({ method: req.method, status_code: 500 });
      }
    );
  }
  catch(err){
    logger.error("Error: " + err);
    res.render("index", { "status": "error", "error": "Error: " + err.message});
  }
};

// Display transfer view.
exports.transfer = function (req, res) {
  logger.debug("creditAPI_URL: " + creditAPI_URL);
  //res.header("Access-Control-Allow-Origin", "*");
  res.render("transfer", {customer: customer, creditAPI_URL: creditAPI_URL });
};

// Display transaction history view.
exports.transactions = function (req, res) {
  //let transactions = [{"date": "2021-01-25 10:25:09 AM", "sourceAccount":"0123456789", "targetAccount": "987654321", "amount": 15000.20}, {"date": "2021-02-18 09:55:09 PM", "sourceAccount":"0123456789", "targetAccount": "548795124", "amount": 4.2}];
  logger.debug("PAYMENT_HISTORY_URL: " + paymentHistory_URL + "/" + customer.accountId)
  axios
    .get(paymentHistory_URL + "/" + customer.accountId)
    .then((response) => {
      let transactions = response.data;
      //logger.debug("transactions: " + transactions);
      res.render("transactions", { "transactions": transactions, "customer": customer });
      //end({ method: req.method, status_code: 200 });
    })
    .catch((error) => {
      logger.error("Error: " + error);
      res.render("transactions", { "status": "error", "error": "Error retrieving payment history." });
      //end({ method: req.method, status_code: 500 });
    });
  //res.render("transactions", { transactions: transactions });
};

exports.post_transfer = function (req, res) {
  
  const end = transfer_histogram.startTimer();

  logger.debug("Here in customerController - > post_tranfser");

  var amount = req.body.amount;
  var sourceAccount = req.body.fromAccountId;
  var targetAccount = req.body.toAccountId;

  logger.debug("amount = " + amount);
  logger.debug("sourceAccount = " + sourceAccount);
  logger.debug("targetAccount = " + targetAccount);

  axios
    .post(creditAPI_URL, {
      amount: amount,
      sourceAccount: sourceAccount,
      targetAccount: targetAccount,
    })
    .then((response) => {
      logger.debug("Response.status = " + response.status);
      logger.debug("response.data = " + response.data);
      result = response.data;
      if (response.status == 200) {
        res.render("transfer", {
          status: "ok",
          error: null,
          amount: amount,
          sourceAccount: sourceAccount,
          targetAccount: targetAccount,
        });
        end({ method: req.method, status_code: 200 });
      } else {
        res.render("transfer", {
          status: "error",
          error: result.message,
          amount: amount,
          sourceAccount: sourceAccount,
          targetAccount: targetAccount,
        });
        end({ method: req.method, status_code: response.status });
      }
    })
    .catch((error) => {
      logger.debug(". Error: " + error);
      res.render("transfer", {
        status: "error",
        error: "Error submitting the credit transfer. Please try again later.",
        amount: amount,
        sourceAccount: sourceAccount,
        targetAccount: targetAccount,
      });
      end({ method: req.method, status_code: 500 });
    });
};

exports.metrics = function (req, res) {
  // Use the prom-client module to expose our metrics to Prometheus
  const prometheus = require("prom-client");
  res.set("Content-Type", prometheus.register.contentType);
  res.send(prometheus.register.metrics());
};

exports.healthz = function (req, res) {
  res.status(200).send("OK");
};