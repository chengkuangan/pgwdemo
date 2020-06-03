// Import credit model
Credit = require('./creditModel');
//Kafka = require('./kafka');
kafka = require('kafka-node');
bp = require('body-parser');
config = require('./config');


// Handle index actions
exports.index = function (req, res) {
    Credit.get(function (err, credits) {
        if (err) {
            res.json({
                status: "error",
                message: err,
            });
        }
        res.json({
            status: "success",
            message: "Credits retrieved successfully",
            data: credits
        });
    });
};

// Handle create credit actions
exports.new = function (req, res) {
    var credit = new Credit();
    credit.amount = req.body.amount;
    credit.targetAccount = req.body.targetAccount;
    credit.sourceAccount = req.body.sourceAccount;
    credit.action = req.body.action;

    var kafkaBootstrap = process.env.KAFKA_BOOTSTRAP_SERVER;
    
    try {
        //const client = new kafka.KafkaClient({kafkaHost: 'kafka-cluster-kafka-bootstrap:9092'});
        console.log("----> Bootstrap Server = " + kafkaBootstrap);

        const client = new kafka.KafkaClient({kafkaHost: kafkaBootstrap});
        const producer = new kafka.Producer(client);
        const kafka_topic = config.kafka_topic;
    
        payloads = [
            { topic: 'credit', messages: JSON.stringify(credit)} 
        ];

        producer.on('ready', async function () {
            let push_status = producer.send(payloads, (err, data) => {
                if (err) {
                    console.log('[kafka-producer -> ' + kafka_topic + ']: broker update failed');
                    console.log ('err = ' + err)
                    return res.status(500).json(err);
                } else {
                    console.log('[kafka-producer -> ' + kafka_topic + ']: broker update success');
                    return res.json({message: 'Credit published to kafka', data: credit });
                }
            });
        });

        producer.on('error', function (err) {
            console.log(err);
            console.log('[kafka-producer -> ' + kafka_topic + ']: connection errored');
            //throw err;
            return res.status(500).json(err);
        });
    }
    catch (e) {
        console.log(e);
        return res.status(500).json(err);
    }
    
    //var kafka = new Kafka(credit);
    //kafka.send();
    
};
