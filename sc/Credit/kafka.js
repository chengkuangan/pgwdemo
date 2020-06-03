
const kafka = require('kafka-node');
const bp = require('body-parser');
const config = require('./config');

function MyKafka(credit) {
    this.credit = credit;
    this.client = new kafka.KafkaClient({kafkaHost: 'kafka-cluster-kafka-bootstrap:9092'});
    this.producer = new kafka.Producer(this.client);
    this.kafka_topic = config.kafka_topic;
    console.log(this.kafka_topic);
}

MyKafka.prototype.send = function () {
    try {

        let payloads = [
            {
                topic: this.kafka_topic,
                messages: this.credit
            }
        ];

        this.producer.on('ready', async function () {
            let push_status = this.producer.send(payloads, (err, data) => {
                if (err) {
                    console.log('[kafka-producer -> ' + this.kafka_topic + ']: broker update failed');
                } else {
                    console.log('[kafka-producer -> ' + this.kafka_topic + ']: broker update success');
                }
            });
        });

        this.producer.on('error', function (err) {
            console.log(err);
            console.log('[kafka-producer -> ' + this.kafka_topic + ']: connection errored');
            throw err;
        });
    }
    catch (e) {
        console.log(e);
    }
}

module.exports = MyKafka;

/*
const kafka = require('kafka-node');
const bp = require('body-parser');
const config = require('./config');
var credit = require('./creditModel');

try {
  const Producer = kafka.Producer;
  const client = new kafka.Client(config.kafka_server);
  const producer = new Producer(client);
  const kafka_topic = config.kafka_topic;
  console.log(kafka_topic);
  let payloads = [
    {
      topic: kafka_topic,
      messages: credit
    }
  ];

  producer.on('ready', async function() {
    let push_status = producer.send(payloads, (err, data) => {
      if (err) {
        console.log('[kafka-producer -> '+kafka_topic+']: broker update failed');
      } else {
        console.log('[kafka-producer -> '+kafka_topic+']: broker update success');
      }
    });
  });

  producer.on('error', function(err) {
    console.log(err);
    console.log('[kafka-producer -> '+kafka_topic+']: connection errored');
    throw err;
  });
}
catch(e) {
  console.log(e);
}
*/