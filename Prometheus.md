## Internal Notes

### Kafka Distributed Tracing
https://access.redhat.com/documentation/en-us/red_hat_amq/7.6/html-single/using_amq_streams_on_openshift/index#assembly-distributed-tracing-str

### OpenTracing Apache Kafka Client Instrumentation
https://github.com/opentracing-contrib/java-kafka-client/blob/master/README.md


## Prometheus

### Nodejs

1. List of all Prometheus client - https://prometheus.io/docs/instrumenting/clientlibs/
2. NodeJs Prometheus Client - https://github.com/siimon/prom-client
3. Promethues metric type - https://prometheus.io/docs/concepts/metric_types/
4. How to enable prometheus for nodejs - https://developers.redhat.com/blog/2018/12/21/monitoring-node-js-applications-on-openshift-with-prometheus/
5. Make sure the following are configure for the services. [Details](https://www.weave.works/docs/cloud/latest/tasks/monitor/configuration-k8s/)
```
prometheus.io/port
prometheus.io/scrape
```

exmaple:
```
  annotations:
    description: Exposes and load balances the application pods
    openshift.io/generated-by: OpenShiftNewApp
    prometheus.io/port: '8080'
    prometheus.io/scrape: 'true'
```    

### SpringBoot Application
1. Refer this url - 
    https://docs.spring.io/spring-metrics/docs/current/public/prometheus
    
    https://access.redhat.com/documentation/en-us/red_hat_support_for_spring_boot/2.2/html-single/spring_boot_runtime_guide/index#exposing-metrics-using-prometheus-with-spring-boot_spring-boot

2. default SpringBoot metrics path is /prometheus, we need to annotates services with the following:
```
prometheus.io/port: '8080'
prometheus.io/scrape: 'true'
prometheus.io/path: '/actuator/prometheus'
```

##### Some Good References
[Micrometer: Spring Boot 2's new application metrics collector](https://spring.io/blog/2018/03/16/micrometer-spring-boot-2-s-new-application-metrics-collector)
[Micrometer Prometheus](https://micrometer.io/docs/registry/prometheus)