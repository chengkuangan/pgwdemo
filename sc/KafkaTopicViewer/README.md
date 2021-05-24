# Overview

This project provides a simple UI to view the real-time messages in Kafka topics in Payment Gateway

To deploy this project into OpenShift:

```
    ./mvnw clean package -DskipTests \
    -Dquarkus.container-image.name=credit-viewer \
    -Dquarkus.container-image.group=$APPS_NAMESPACE \
    -Dquarkus.kubernetes-client.trust-certs=true -Dquarkus.kubernetes.deploy=true \
    -Dquarkus.openshift.env-vars.kafka-bootstrap-servers.value=<kafka_bootstrap_servers> \
    -Dquarkus.openshift.env-vars.kafka-topic.value=<kafka_topic> \
    "-Dquarkus.openshift.env-vars.ui-index-title.value=Payment Gateway - Kafka credit Topic Viewer" \
    -Dquarkus.openshift.env-vars.kafka-consumer-group-id.value=<kafka_consumer_group_id> \
    -Dquarkus.openshift.name=<deployment_name_on_ocp> \
    -Dquarkus.openshift.labels.app=<deployment_name_on_ocp> \
    -Dquarkus.kubernetes.namespace=$APPS_NAMESPACE

```

To deploy UI for `credit` topic:

```
    oc project paygate

    ./mvnw clean package -DskipTests \
    -Dquarkus.container-image.name=credit-viewer \
    -Dquarkus.container-image.group=paygate \
    -Dquarkus.kubernetes-client.trust-certs=true -Dquarkus.kubernetes.deploy=true \
    -Dquarkus.openshift.env-vars.kafka-bootstrap-servers.value=<kafka_bootstrap_servers> \
    -Dquarkus.openshift.env-vars.kafka-topic.value=credit \
    "-Dquarkus.openshift.env-vars.ui-index-title.value=Payment Gateway - Kafka credit Topic Viewer" \
    -Dquarkus.openshift.env-vars.kafka-consumer-group-id.value=credit-viewer \
    -Dquarkus.openshift.name=credit-viewer \
    -Dquarkus.openshift.labels.app=credit-viewer \
    -Dquarkus.kubernetes.namespace=paygate

```

To deploy UI for `credit-response` topic:

```
    oc project paygate

    ./mvnw clean package -DskipTests \
    -Dquarkus.container-image.name=credit-response-viewer \
    -Dquarkus.container-image.group=paygate \
    -Dquarkus.kubernetes-client.trust-certs=true -Dquarkus.kubernetes.deploy=true \
    -Dquarkus.openshift.env-vars.kafka-bootstrap-servers.value=<kafka_bootstrap_servers> \
    -Dquarkus.openshift.env-vars.kafka-topic.value=credit-response \
    "-Dquarkus.openshift.env-vars.ui-index-title.value=Payment Gateway - Kafka credit-response Topic Viewer" \
    -Dquarkus.openshift.env-vars.kafka-consumer-group-id.value=credit-response-viewer \
    -Dquarkus.openshift.name=credit-response-viewer \
    -Dquarkus.openshift.labels.app=credit-response \
    -Dquarkus.kubernetes.namespace=paygate

```

Note:
- `quarkus.container-image.name` produces inconsistence outcomes. The best is to modify pom.xml `<artifactId></artifactId>` to have the POD deployed with the name that you want.
- `quarkus.kubernetes.namespace` does not work as expected. You should manually change to the OpenShift project that you want to deploy with `oc project` command.
- The messages in the Kafka topic must be simple JSON string. The UI service is directly using the JSON messages to contstruct the [DataTables](https://datatables.net/) during runtime.
- The UI service only read from the position for the last consumed messages. Thus you will not see the consumed messages if you refresh or re-open the UI on the browser.