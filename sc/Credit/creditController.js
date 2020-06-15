// Import credit model
Credit = require("./creditModel");
kafka = require("kafka-node");
bp = require("body-parser");
config = require("./config");
const prometheus = require("./lib/prometheus");
const logger = require("./lib/logger");


const new_histogram = prometheus.histogram(
  "pgw_creditservice:create_duration",
  "Duration of Create Credit HTTP requests in ms",
  ["method", "status_code"],
  [0.1, 5, 15, 50, 100, 500]
);

/*
const new_counter = new prometheus.Counter({
    name: 'metric_name',
    help: 'Duration of Create Credit HTTP requests in ms',
    registers: [registry],
  });
*/

// Handle index actions
exports.index = function (req, res) {
  Credit.get(function (err, credits) {
    if (err) {
      res.json({
        status: "error",
        message: err,
      });
    } else {
      res.json({
        status: "success",
        message: "Credits retrieved successfully",
        data: credits,
      });
    }
  });
};

// Handle create credit actions
exports.create = function (req, res) {
  
  logger.info("In POST: /ws/pg/credits");
  
  const end = new_histogram.startTimer();
  var credit = new Credit();
  credit.amount = req.body.amount;
  credit.targetAccount = req.body.targetAccount;
  credit.sourceAccount = req.body.sourceAccount;
  credit.action = req.body.action;

  var kafkaBootstrap = process.env.KAFKA_BOOTSTRAP_SERVER;
  
  try {
    //const client = new kafka.KafkaClient({kafkaHost: 'kafka-cluster-kafka-bootstrap:9092'});
    logger.debug("Bootstrap Server = " + kafkaBootstrap);

    const client = new kafka.KafkaClient({ kafkaHost: kafkaBootstrap });
    const producer = new kafka.Producer(client);
    const kafka_topic = config.kafka_topic;

    payloads = [{ topic: "credit", messages: JSON.stringify(credit) }];

    producer.on("ready", async function () {
      let push_status = producer.send(payloads, (err, data) => {
        if (err) {
          logger.error(
            "[kafka-producer -> " + kafka_topic + "]: broker update failed"
          );
          logger.error("err = " + err);
          end({ method: req.method, status_code: 500 });
          return res.status(500).json(err);
        } else {
          logger.debug(
            "[kafka-producer -> " + kafka_topic + "]: broker update success"
          );
          end({ method: req.method, status_code: 200 });
          return res.json({
            message: "Credit published to kafka",
            data: credit,
          });
        }
      });
    });

    producer.on("error", function (err) {
      logger.error(err);
      logger.debug(
        "[kafka-producer -> " + kafka_topic + "]: connection errored"
      );
      end({ method: req.method, status_code: 500 });
      //throw err;
      return res.status(500).json(err);
    });
  } catch (e) {
    logger.error(e);
    end({ method: req.method, status_code: 500 });
    return res.status(500).json(err);
  }

};

exports.metrics = function (req, res) {
    // Use the prom-client module to expose our metrics to Prometheus
    const prometheus = require("prom-client");
    res.set("Content-Type", prometheus.register.contentType);
    res.send(prometheus.register.metrics());
};