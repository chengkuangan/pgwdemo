
// Use the prom-client module to expose our metrics to Prometheus
const prom = require("prom-client");
// enable prom-client to expose default application metrics
const collectDefaultMetrics = prom.collectDefaultMetrics;

collectDefaultMetrics({ prefix: "creditservice:" });

exports.histogram = function(name, help, labelNames, buckets){
  // a custom histogram metric which represents the latency
  const histogram = new prom.Histogram({
    name: name,
    help: help,
    labelNames: labelNames,
    buckets: buckets,
  });
  
  return histogram;

}