#!/bin/bash

########################################################################################################################
### 
### Installation script for Payment Gateway Demo.
### Contributed By: CK Gan (chgan@redhat.com)
### Complete demo setup guide is at https://github.com/chengkuangan/pgwdemo
### 
########################################################################################################################

APPS_NAMESPACE="paygate"
KAFKA_CLUSTER_NAME="kafka-cluster"
APPS_PROJECT_DISPLAYNAME="Payment Gateway"
APP_DOMAIN_NAME="apps.ocpcluster1.gemsdemolab.com"
RHSSO_NAMESPACE="rhsso"
OC_USER=""
SSO_APPNAME="sso"
SSO_ADMIN_USERNAME="admin"
SSO_ADMIN_PASSWORD="password"
STRIMZI_SLACKAPI_URL="https:\/\/ssa-mr19696.slack.com"
STRIMZI_SLACK_CHANNEL="#paygate-strimzi"
PROCEED_INSTALL="no"

### ------
# @Deprecated
KAFKA_NAMESPACE=$APPS_NAMESPACE
PRREFIX_NAMESPACE="yes"
INSTALL_PROMETHEUS="no"
INSTALL_BASIC_DEMO="no"
### ------

function init(){
    
    set echo off
    OC_USER="$(oc whoami)"
    set echo on
    
    if [ $? -ne 0 ] || [ "$OC_USER" = "" ]; then
        echo
        echo "Please login to Openshift before proceed..."
        echo
        exit 0
    fi
    echo
    echo "--> Creating temporary directory ../tmp "
    mkdir ../tmp
}

function printVariables(){
    echo 
    echo "The following is the parameters enter..."
    echo
    echo "APPS_NAMESPACE = $APPS_NAMESPACE"
    echo "APPS_PROJECT_DISPLAYNAME = $APPS_PROJECT_DISPLAYNAME"
    echo "KAFKA_CLUSTER_NAME = $KAFKA_CLUSTER_NAME"
    echo "RHSSO_NAMESPACE = $RHSSO_NAMESPACE"
    echo "SSO_ADMIN_USERNAME = $SSO_ADMIN_USERNAME"
    echo "SSO_ADMIN_PASSWORD = $SSO_ADMIN_PASSWORD"
    echo "SSO_APPNAME = $SSO_APPNAME"
    echo "APP_DOMAIN_NAME = $APP_DOMAIN_NAME"
    echo "OC_USER = $OC_USER"
    echo "STRIMZI_SLACKAPI_URL = $STRIMZI_SLACKAPI_URL"
    echo "STRIMZI_SLACK_CHANNEL = $STRIMZI_SLACK_CHANNEL"
    echo

}

function preRequisitionCheck(){
    ## --- Check if the Kafka yaml files are in the kafka-resource folder
    if [ ! -d "../kafka-resources/install/cluster-operator" ]; then
        echo
        echo "Missing AMQ Streams OCP Install YMAL files..."
        echo
        echo "Please download AMQ Streams OCP Install YAML files from Red Hat website and place them into the kafka-resources directory."
        echo "The directory structure should looks something like this..."
        echo "kafka-resources/install"
        echo "kafka-resources/examples"
        echo
        removeTempDirs
        exit 0
    fi 

    hash jq
    
    if [ $? -ne 0 ]; then
        echo
        echo "You will required jq command line JSON processor ... "
        echo "Please download and install the command line tool from here ... https://stedolan.github.io/jq/"
        echo
        removeTempDirs
        exit 0
    fi

    oc project $RHSSO_NAMESPACE
    
    if [ $? -ne 0 ]; then
        echo
        echo "Please ensure you have the following OpenShift projects created before proceed ... "
        echo "   * $RHSSO_NAMESPACE"
        echo "   * $APPS_NAMESPACE"
        echo
        removeTempDirs
        exit 0
    fi

    oc project $APPS_NAMESPACE

    if [ $? -ne 0 ]; then
        echo
        echo "Please ensure you have the following OpenShift projects created before proceed ... "
        echo "   * $RHSSO_NAMESPACE"
        echo "   * $APPS_NAMESPACE"
        echo
        removeTempDirs
        exit 0
    fi
    #TODO
    ## To add pre-req checking whether the requried operator has been installed.
}


# @Deprecated
function updateKafkaResourcesFiles(){
    ## --- Update Kafka *RoleBinding*.yaml files
    if [ $DEPLOY_KAFKA_OPERATOR = "yes" ]; then
        echo 
        echo "--> Changing all namespace entries in install/cluster-operator/*RoleBinding*.yaml to $KAFKA_OPERATOR_NAMESPACE"
        sed -i -e 's/namespace: .*/namespace: '"$KAFKA_OPERATOR_NAMESPACE"'/' ../kafka-resources/install/cluster-operator/*RoleBinding*.yaml
    fi

    ## --- Update kafka cluster name
    echo
    echo "--> Changing Kafka.metadata.name property value to $KAFKA_CLUSTER_NAME in ../kafka-resources/examples/kafka/kafka-persistent.yaml"
    sed -i -e "s/name: .*/name: $KAFKA_CLUSTER_NAME/" ../kafka-resources/examples/kafka/kafka-persistent.yaml
    #sed -i -e '' 's/name: .*/name: '"$KAFKA_CLUSTER_NAME"'/' ../kafka-resources/examples/kafka/kafka-persistent.yaml
    # sed -i -e 's/name: .*/name: $KAFKA_NAMESPACE-kafka-cluster/' ../kafka-resources/examples/kafka/kafka-persistent.yaml
    
    count=$(grep -c "topicOperator:" ../kafka-resources/examples/kafka/kafka-persistent.yaml)

    #sed -i -e 's/.*entityOperator.*/ /' ../kafka-resources/examples/kafka/kafka-persistent.yaml
    #sed -i -e 's/.*topicOperator.*/ /' ../kafka-resources/examples/kafka/kafka-persistent.yaml
    #sed -i -e 's/.*userOperator.*/ /' ../kafka-resources/examples/kafka/kafka-persistent.yaml
    
    if [ $count = 0 ]; then
        echo
        echo "--> Appending Kafka Topic Operator settings into ../kafka-resources/examples/kafka/kafka-persistent.yaml"
        echo "  entityOperator:" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo "    topicOperator:" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo "      watchedNamespace: $KAFKA_NAMESPACE" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo "      reconciliationIntervalSeconds: 90" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo "      zookeeperSessionTimeoutSeconds: 20" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo "      topicMetadataMaxAttempts: 6" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo "      image: registry.redhat.io/amq7/amq-streams-operator:1.3.0" >> ../kafka-resources/examples/kafka/kafka-persistent.yaml
        echo
    fi

    ## --- Update kafka connect yaml file
    echo
    echo "--> Changing properties in ../kafka-resources/examples/kafka-connect/kafka-connect.yaml"
    sed -i -e 's/name: .*/name: mongodb-connect-cluster/' ../kafka-resources/examples/kafka-connect/kafka-connect.yaml
    sed -i -e 's/bootstrapServers: .*/bootstrapServers: '"$KAFKA_NAMESPACE"'-kafka-cluster-kafka-bootstrap:9093/' ../kafka-resources/examples/kafka-connect/kafka-connect.yaml
    # sed -i -e 's/bootstrapServers: .*/bootstrapServers: '"$KAFKA_NAMESPACE"'-kafka-cluster-kafka-bootstrap:9093/' ../kafka-resources/examples/kafka-connect/kafka-connect.yaml
    sed -i -e 's/secretName: .*/secretName: '"$KAFKA_NAMESPACE"'-kafka-cluster-cluster-ca-cert/' ../kafka-resources/examples/kafka-connect/kafka-connect.yaml
    echo "  image: docker.io/chengkuan/amq-streams-kafka-connect-23:1.3.0" >> ../kafka-resources/examples/kafka-connect/kafka-connect.yaml
    echo

}

function deployKafka(){
    # ---- Not in used now, temporary remove for future improvement ...
    #if [ $DEPLOY_KAFKA_OPERATOR = "yes" ]; then
    #    echo 
    #    echo "--> Deploying AMQ Streams (Kafka) Operator now ... Using ../kafka-resources/install/cluster-operator ... "
    #    oc apply -f ../kafka-resources/install/cluster-operator -n $KAFKA_OPERATOR_NAMESPACE
    #fi
    echo
    echo "--> Modifying ../templates/kafka/kafka-persistent.yaml"
    echo
    mkdir ../tmp/kafka
    cp ../templates/kafka/kafka-persistent.yaml ../tmp/kafka/kafka-persistent.yaml
    sed -i -e "s/paygate/$APPS_NAMESPACE/" ../tmp/kafka/kafka-persistent.yaml
    echo 
    echo "--> Deploying AMQ Streams (Kafka) Cluster now ... Using ../kafka-resources/examples/kafka/kafka-persistent.yaml ..."
    oc apply -f ../tmp/kafka/kafka-persistent.yaml -n $APPS_NAMESPACE
    echo
}

# ----- Create the necessary name space.
function createNamespaces(){
    echo
    echo "--> Creating the necessary projects ... "
    oc new-project $APPS_NAMESPACE --display-name="$APPS_PROJECT_DISPLAYNAME"
}

## --- Deploy CreditResponse MongoDB
function deployCRMDB(){
    echo 
    echo "--> Deploying Credit Response Mongodb database ..."
    oc new-app -f ../templates/creditresponse-mongodb-deployment-template.yaml -n $APPS_NAMESPACE
}

## --- Perform necessary configuration after CreditResponse MongoDB POD is ready
function postDeployCreditResponseMongoDBConfig(){
    echo
    echo "--> Perfoming post deployment configuration ... "
    echo 
    echo "--> Patching Credit Response Mongodb ..."
    # CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep $CREDITRESPONSE_MONGODB_NAME.[0-9].[^deploy])"
    CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep creditresponse-[0-9] | grep -v creditresponse-[0-9]-deploy)"
    # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n payment-gateway | grep creditresponse.[0-9].[^deploy]
    while [ "$CREDITRESPONSE_MONGODB_POD_NAME" = "" ]
        do
            sleep 10
            # CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep $CREDITRESPONSE_MONGODB_NAME.[0-9].[^deploy])"
            CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep creditresponse-[0-9] | grep  -v creditresponse-[0-9]-deploy)"
            # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n payment-gateway | grep creditresponse-[0-9]-.[^deploy]
            echo "Waiting for POD to to be created ... POD Name: $CREDITRESPONSE_MONGODB_POD_NAME"
        done
    CREDITRESPONSE_MONGODB_POD_READY="false"
    while [ "$CREDITRESPONSE_MONGODB_POD_READY" = "false" ]
        do
            sleep 10
            CREDITRESPONSE_MONGODB_POD_READY="$(oc get pod ${CREDITRESPONSE_MONGODB_POD_NAME} -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
            # oc get pod creditresponse-1-dgkpk -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n pg
            echo "Waiting for POD to be ready... POD: $CREDITRESPONSE_MONGODB_POD_NAME, ready: $CREDITRESPONSE_MONGODB_POD_READY ..."
        done
    oc cp ../scripts/crmdb.js $CREDITRESPONSE_MONGODB_POD_NAME:/tmp/ -n $APPS_NAMESPACE
    oc exec $CREDITRESPONSE_MONGODB_POD_NAME -- scl enable rh-mongodb32 -- mongo localhost:27017/admin /tmp/crmdb.js -n $APPS_NAMESPACE
}

# ----- Deploy Kafka Connect
function deployKafkaConnect(){
    echo
    echo "--> Deploy Kafka Connect ..."
    echo "Waiting for Kafka to be ready ..."
    KAFKA_POD_READY="$(oc get pod $KAFKA_CLUSTER_NAME-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
    while [ $? -ne 0 ]
        do
            echo "$KAFKA_CLUSTER_NAME-kafka-0 is not created yet ... Waiting ... "
            sleep 10
            KAFKA_POD_READY="$(oc get pod $KAFKA_CLUSTER_NAME-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
        done
    echo "POD: $KAFKA_CLUSTER_NAME-kafka-0, ready: $KAFKA_POD_READY"
    # oc get pod pg-kafka-cluster-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n pg
    while [ "$KAFKA_POD_READY" = "false" ]
        do  
            sleep 10
            KAFKA_POD_READY="$(oc get pod $KAFKA_CLUSTER_NAME-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
            echo "POD: $KAFKA_CLUSTER_NAME-kafka-0, ready: $KAFKA_POD_READY"
        done
    oc apply -f ../templates/kafka/kafka-connect/kafka-connect.yaml -n $APPS_NAMESPACE
}

## --- configure kafka connect for Credit Response mongodb
function configureKafkaConnect4CRMDB(){
    echo
    echo "--> Configuring Kafka Connect for CreditResponse Mongodb ... "

    #MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect)"
    MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect-[0-9] | grep -v mongodb-connect-cluster-connect-[0-9]-deploy)"
    # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect)
    echo "Waiting for POD to to be created ... POD Name: $MONGODB_KAFKA_CONNECT_POD_NAME"
    while [ "$MONGODB_KAFKA_CONNECT_POD_NAME" = "" ]
        do
            sleep 10
            #MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect)"
            MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect-[0-9] | grep -v mongodb-connect-cluster-connect-[0-9]-deploy)"
            echo "Waiting for POD to to be created ... POD Name: $MONGODB_KAFKA_CONNECT_POD_NAME"
        done
    echo "Waiting for pod to be ready ..."
    MONGODB_KAFKA_CONNECT_POD_READY="$(oc get pod $MONGODB_KAFKA_CONNECT_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
    echo "POD: $MONGODB_KAFKA_CONNECT_POD_NAME, ready: $MONGODB_KAFKA_CONNECT_POD_READY"
    while [ "$MONGODB_KAFKA_CONNECT_POD_READY" = "false" ]
        do
            sleep 10
            MONGODB_KAFKA_CONNECT_POD_READY="$(oc get pod $MONGODB_KAFKA_CONNECT_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
            echo "POD: $MONGODB_KAFKA_CONNECT_POD_NAME, ready: $MONGODB_KAFKA_CONNECT_POD_READY"
        done
    oc cp ../sc/CreditResponseMongoDB/connect-mongodb-sink.json $MONGODB_KAFKA_CONNECT_POD_NAME:/tmp/ -n $APPS_NAMESPACE
    MESSAGE=$(oc -n $APPS_NAMESPACE exec $MONGODB_KAFKA_CONNECT_POD_NAME -- curl -d @/tmp/connect-mongodb-sink.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors)
    if [[ $MESSAGE == *"error_code"* ]] ; then
        echo
        echo "Error configuring MongoDB Kafka Connect. Please check the log for more details. Please verify the content is correct in ./CreditResponseMongoDB/connect-mongodb-sink.json"
    fi
    echo
}

# ----- Deploy RHSSO and configure the necessary realms and users.
function deployRHSSO(){
    echo 
    echo "--> Deploy RHSSO ..."
    echo

    #oc new-project $RHSSO_NAMESPACE
    oc policy add-role-to-user view system:serviceaccount:$RHSSO_NAMESPACE:default -n $RHSSO_NAMESPACE

    mkdir ../tmp/sso
    echo
    echo "Generating required certs and keystores for RHSSO ..."
    echo
    openssl req -new -newkey rsa:4096 -x509 -keyout ../tmp/sso/xpaas.key -out ../tmp/sso/xpaas.crt -passout pass:openshift -days 365 -subj "/CN=xpaas-sso-demo.ca"
    keytool -genkeypair -keyalg RSA -keysize 2048 -dname "CN=secure-sso-chgan-rhsso.apps.ocpcluster1.gemsdemolab.com" -alias jboss -storepass mykeystorepass -keystore ../tmp/sso/keystore.jks
    keytool -certreq -keyalg rsa -alias jboss -storepass mykeystorepass -keystore ../tmp/sso/keystore.jks -file ../tmp/sso/sso.csr
    openssl x509 -req -CA ../tmp/sso/xpaas.crt -CAkey ../tmp/sso/xpaas.key -in ../tmp/sso/sso.csr -out ../tmp/sso/sso.crt -days 365 -CAcreateserial -passin pass:openshift
    keytool -import -file ../tmp/sso/xpaas.crt -alias ../tmp/sso/xpaas.ca -keystore ../tmp/sso/keystore.jks -noprompt -trustcacerts -storepass mykeystorepass
    keytool -import -file ../tmp/sso/sso.crt -alias jboss -keystore ../tmp/sso/keystore.jks -noprompt -storepass mykeystorepass
    keytool -genseckey -alias secret-key -storetype JCEKS -keystore ../tmp/sso/jgroups.jceks -storepass password -keypass password
    keytool -import -file ../tmp/sso/xpaas.crt -alias xpaas.ca -keystore ../tmp/sso/truststore.jks -noprompt -trustcacerts -storepass mykeystorepass
    
    echo
    echo "Creating secret for RHSSO ..."
    echo
    oc create secret generic sso-app-secret --from-file=../tmp/sso/keystore.jks --from-file=../tmp/sso/jgroups.jceks --from-file=../tmp/sso/truststore.jks -n $RHSSO_NAMESPACE
    oc secrets link default sso-app-secret -n $RHSSO_NAMESPACE

    echo
    echo "Deploying RHSSO using template ..."
    echo
    oc new-app --template=sso73-https -n $RHSSO_NAMESPACE \
    -p APPLICATION_NAME=$SSO_APPNAME \
    -p HTTPS_SECRET="sso-app-secret" \
    -p HTTPS_KEYSTORE="keystore.jks" \
    -p HTTPS_NAME="jboss" \
    -p HTTPS_PASSWORD="mykeystorepass" \
    -p JGROUPS_ENCRYPT_SECRET="sso-app-secret" \
    -p JGROUPS_ENCRYPT_KEYSTORE="jgroups.jceks" \
    -p JGROUPS_ENCRYPT_NAME="secret-key" \
    -p JGROUPS_ENCRYPT_PASSWORD="password" \
    -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME \
    -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD \
    -p SSO_TRUSTSTORE="truststore.jks" \
    -p SSO_TRUSTSTORE_PASSWORD="mykeystorepass" \
    -p SSO_TRUSTSTORE_SECRET="sso-app-secret"

    #oc new-app --template=sso73-x509-postgresql-persistent -n $RHSSO_NAMESPACE -p APPLICATION_NAME=$SSO_APPNAME -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD -p POSTGRESQL_IMAGE_STREAM_TAG=latest
    #oc new-app --template=sso73-postgresql-persistent -n $RHSSO_NAMESPACE -p APPLICATION_NAME=$SSO_APPNAME -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD -p POSTGRESQL_IMAGE_STREAM_TAG=latest
    #oc new-app --template=sso73-https -n $RHSSO_NAMESPACE -p APPLICATION_NAME=$SSO_APPNAME -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD
    
    echo
    echo "Configure RHSSO PaymentGateway Realms..."
    echo

    SSO_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $RHSSO_NAMESPACE | grep $SSO_APPNAME-[0-9] | grep -v $SSO_APPNAME-[0-9]-deploy)"
    # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n rhsso | grep sso.[0-9].[^deploy]
    echo "Waiting for POD to to be created ... POD Name: $SSO_POD_NAME"
    while [ "$SSO_POD_NAME" = "" ]
        do
            sleep 10
            SSO_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $RHSSO_NAMESPACE | grep $SSO_APPNAME-[0-9] | grep -v $SSO_APPNAME-[0-9]-deploy)"
            echo "Waiting for POD to to be created ... POD Name: $SSO_POD_NAME"
        done
    echo "Waiting for pod to be ready ..."
    SSO_POD_READY="$(oc get pod $SSO_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $RHSSO_NAMESPACE)"
    echo "POD: $SSO_POD_NAME, ready: $SSO_POD_READY"
    while [ "$SSO_POD_READY" = "false" ]
        do
            sleep 10
            SSO_POD_READY="$(oc get pod $SSO_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $RHSSO_NAMESPACE)"
            echo "POD: $SSO_POD_NAME, ready: $SSO_POD_READY"
        done

    cp ../templates/paymentgateway-realm.json ../tmp/sso/
    sed -i -e "s/http:\/\/customeraccount:3000/http:\/\/customer-ui-$APPS_NAMESPACE.$APP_DOMAIN_NAME/" ../tmp/sso/paymentgateway-realm.json

    oc cp ../tmp/sso/paymentgateway-realm.json $SSO_POD_NAME:/tmp/ -n $RHSSO_NAMESPACE

    MESSAGE=$(oc -n $RHSSO_NAMESPACE exec $SSO_POD_NAME -- curl -k -X POST "http://sso:8080/auth/realms/master/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=$SSO_ADMIN_USERNAME" -d "password=$SSO_ADMIN_PASSWORD" -d "grant_type=password" -d "client_id=admin-cli")
    if [[ $MESSAGE == *"error_code"* ]] ; then
        echo
        echo "Error getting access token from RHSSO at Pod:$SSO_POD_NAME. Please check the log for more details."
    else
        TOKEN=$(echo $MESSAGE | jq -r '.access_token')
        MESSAGE=$(oc -n $RHSSO_NAMESPACE exec $SSO_POD_NAME -- curl -k -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @/tmp/paymentgateway-realm.json http://sso:8080/auth/admin/realms)
        if [[ $MESSAGE == *"error_code"* ]] ; then
            echo
            echo "Error importing PaymentGateway Realm. Using $SSO_POD_NAME:/tmp/paymentgateway-realm.json"
        fi
    fi
    
}

# ----- Build and deploy Account Service
function deployAccountService(){
    echo
    echo "--> Deploying Account Service and DB Service ... "
    echo

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/accountservice-templates.yaml
    
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    oc annotate --overwrite svc accountservice prometheus.io/scrape='true' prometheus.io/port='8080' prometheus.io/path=/actuator/prometheus -n $APPS_NAMESPACE

    mkdir ../tmp/accountservice && cp -r ../sc/AccountService/* ../tmp/accountservice/ && rm -f ../tmp/accountservice/README.adoc && rm -rf ../tmp/accountservice/target
    oc start-build accountservice --from-file=../tmp/accountservice/ -n $APPS_NAMESPACE

}

# ----- Build and deploy Credit Service
function deployCreditService(){
    echo
    echo "--> Deploying Credit Services ... "
    echo

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/creditservice-template.json -p KAFKA_BOOTSTRAP_SERVER=$KAFKA_CLUSTER_NAME-kafka-bootstrap:9092
    
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    oc annotate --overwrite svc creditservice prometheus.io/scrape='true' prometheus.io/port='8080' -n $APPS_NAMESPACE

    mkdir ../tmp/creditservice && cp -r ../sc/Credit/* ../tmp/creditservice/ && rm -f ../tmp/creditservice/README.adoc && rm -rf ../tmp/creditservice/node_modules
    oc start-build creditservice --from-file=../tmp/creditservice/ -n $APPS_NAMESPACE

}

# ----- Deploy Event Correlator service
function deployEventCorrelator(){

    echo
    echo "--> Deploying Event Correlator Services ... "
    echo

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/eventcorrelator-templates.yaml \
    -p KAFKA_BOOTSTRAP_SERVER=$KAFKA_CLUSTER_NAME-kafka-bootstrap:9092 \
    -p ACCOUNT_BALANCE_POST_URL=http://accountservice:8080/ws/pg/balance \
    -p ACCOUNT_BALANCE_GET_URL=http://accountservice:8080/ws/pg/balance
   
    # oc new-app -n pg --allow-missing-imagestream-tags=true -f ../templates/eventcorrelator-templates.yaml -p KAFKA_BOOTSTRAP_SERVER=pg-kafka-cluster-kafka-bootstrap:9093 -p ACCOUNT_BALANCE_POST_URL=http://accountbalance:8080/ws/pg/balance -p ACCOUNT_BALANCE_GET_URL=http://accountbalance:8080/ws/pg/balance

    mkdir ../tmp/eventcorrelator && cp -r ../sc/EventCorrelator/* ../tmp/eventcorrelator/ && rm -f ../tmp/eventcorrelator/README.adoc && rm -rf ../tmp/eventcorrelator/target
    oc start-build event-correlator --from-file=../tmp/eventcorrelator/ -n $APPS_NAMESPACE
    
}

# ----- Build and deploy Account Profile
function deployAccountProfile(){

    echo
    echo "--> Deploying Account Profile services ... "
    echo

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/accountprofile-templates.yaml
    
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    oc annotate --overwrite svc accountprofile prometheus.io/scrape='true' prometheus.io/port='8080' prometheus.io/path=/actuator/prometheus -n $APPS_NAMESPACE

    mkdir ../tmp/accountprofile && cp -r ../sc/AccountProfile/* ../tmp/accountprofile/ && rm -f ../tmp/accountprofile/README.adoc && rm -rf ../tmp/accountprofile/target
    oc start-build accountprofile --from-file=../tmp/accountprofile/ -n $APPS_NAMESPACE

}

# ----- Build and deploy CustomerService, which is a Camel Service.
function deployCustomerCamelService(){

    echo
    echo "--> Deploying Customer Camel Services ... "
    echo 

    
    mkdir ../tmp/customerservice && cp -r ../sc/CustomerService/* ../tmp/customerservice/ && rm -f ../tmp/customerservice/README.adoc && rm -rf ../tmp/customerservice/target
    cd ../tmp/customerservice

    # The OCP Deployment settings is in fabric8/deployment.xml
    oc project $APPS_NAMESPACE
    #mvn clean install fabric8:deploy -Dfabric8.deploy.createExternalUrls=true fabric8:log 
    mvn clean install fabric8:deploy -Dfabric8.deploy.createExternalUrls=false -Dopenshift.namespace=$APPS_NAMESPACE
    #mvn -DCUST_PROFILE_HOST=accountprofile -DCUST_PROFILE_PORT=8080 -DACC_SERVICE_HOST=accountservice -DACC_SERVICE_PORT=8080 -DSERVICE_PORT=8080 clean install fabric8:deploy -Dfabric8.deploy.createExternalUrls=true fabric8:log 

    cd ../../bin
}

# ----- Build and deploy Customer UI
function deployCustomerUI(){
    echo
    echo "--> Deploying Customer UI ... "
    echo

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true \
    -f ../templates/customerui-template.json \
    -p RHSSO_URL=http://$SSO_APPNAME-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME
    #-p CREDIT_API_URL=http://creditservice-chgan-payment-gateway.apps.ocpcluster1.gemsdemolab.com/ws/pg/credits \
    
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    oc annotate --overwrite svc customer-ui prometheus.io/scrape='true' prometheus.io/port='8080' -n $APPS_NAMESPACE
    
    mkdir ../tmp/customerui && cp -r ../sc/CustomerUI/* ../tmp/customerui/  && rm -f ../tmp/customerui/README.adoc && rm -rf ../tmp/customerui/node_modules
    sed -i -e "s/http:\/\/localhost:8080\/auth/http:\/\/$SSO_APPNAME-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME\/auth/" ../tmp/customerui/keycloak.json
    oc start-build customer-ui --from-file=../tmp/customerui/ -n $APPS_NAMESPACE
    
}

# ----- Import the demo sample data into the respective database 
function importSampleData(){
   
    echo
    echo "--> Importing demo data for AccountService mongodb ... "
    echo

    ACCOUNT_SERVICE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountservice-mongodb-[0-9] | grep -v accountservice-mongodb-[0-9]-deploy)"
    echo "Waiting for POD to to be created ... POD Name: $ACCOUNT_SERVICE_MONGODB_POD_NAME"
    while [ "$ACCOUNT_SERVICE_MONGODB_POD_NAME" = "" ]
        do
            sleep 10
            ACCOUNT_SERVICE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountservice-mongodb-[0-9] | grep -v accountservice-mongodb-[0-9]-deploy)"
            echo "Waiting for POD to to be created ... POD Name: $ACCOUNT_SERVICE_MONGODB_POD_NAME"
        done
    echo "Waiting for pod to be ready ..."
    ACCOUNT_SERVICE_MONGODB_POD_READY="$(oc get pod $ACCOUNT_SERVICE_MONGODB_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
    echo "POD: $ACCOUNT_SERVICE_MONGODB_POD_NAME, ready: $ACCOUNT_SERVICE_MONGODB_POD_READY"
    while [ "$ACCOUNT_SERVICE_MONGODB_POD_READY" = "false" ]
        do
            sleep 10
            ACCOUNT_SERVICE_MONGODB_POD_READY="$(oc get pod $ACCOUNT_SERVICE_MONGODB_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
            echo "POD: $ACCOUNT_SERVICE_MONGODB_POD_NAME, ready: $ACCOUNT_SERVICE_MONGODB_POD_READY"
        done
    echo
    echo "Importing sample data into $ACCOUNT_SERVICE_MONGODB_POD_NAME ..."
    oc -n $APPS_NAMESPACE cp ../tmp/accountservice/src/main/resources/sampledata.json $ACCOUNT_SERVICE_MONGODB_POD_NAME:/tmp/ 
    oc -n $APPS_NAMESPACE exec $ACCOUNT_SERVICE_MONGODB_POD_NAME -- mongoimport --db accountservice --collection balance --authenticationDatabase accountservice --username accountservice --password accountservice --drop --file /tmp/sampledata.json

    echo
    echo "--> Importing demo data for AccountProfile mongodb ... "
    echo

    ACCOUNT_PROFILE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountprofile-mongodb-[0-9] | grep -v accountprofile-mongodb-[0-9]-deploy)"
    echo "Waiting for POD to to be created ... POD Name: $ACCOUNT_PROFILE_MONGODB_POD_NAME"
    while [ "$ACCOUNT_PROFILE_MONGODB_POD_NAME" = "" ]
        do
            sleep 10
            ACCOUNT_PROFILE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountprofile-mongodb-[0-9] | grep -v accountprofile-mongodb-[0-9]-deploy)"
            echo "Waiting for POD to to be created ... POD Name: $ACCOUNT_PROFILE_MONGODB_POD_NAME"
        done
    echo "Waiting for pod to be ready ..."
    ACCOUNT_PROFILE_MONGODB_POD_READY="$(oc get pod $ACCOUNT_PROFILE_MONGODB_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
    echo "POD: $ACCOUNT_PROFILE_MONGODB_POD_NAME, ready: $ACCOUNT_PROFILE_MONGODB_POD_READY"
    while [ "$ACCOUNT_PROFILE_MONGODB_POD_READY" = "false" ]
        do
            sleep 10
            ACCOUNT_PROFILE_MONGODB_POD_READY="$(oc get pod $ACCOUNT_PROFILE_MONGODB_POD_NAME -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $APPS_NAMESPACE)"
            echo "POD: $ACCOUNT_PROFILE_MONGODB_POD_NAME, ready: $ACCOUNT_PROFILE_MONGODB_POD_READY"
        done
    echo
    echo "Importing sample data into $ACCOUNT_PROFILE_MONGODB_POD_NAME ..."
    oc -n $APPS_NAMESPACE cp ../tmp/accountprofile/src/main/resources/sampledata.json $ACCOUNT_PROFILE_MONGODB_POD_NAME:/tmp/
    oc -n $APPS_NAMESPACE exec $ACCOUNT_PROFILE_MONGODB_POD_NAME -- mongoimport --db accountprofile --collection account --authenticationDatabase accountprofile --username accountprofile --password accountprofile --drop --file /tmp/sampledata.json

}   

# ----- Remove all tmp content after completed.
function removeTempDirs(){
    echo
    echo "--> Removing ../tmp directory ... "
    echo
    rm -rf ../tmp
}

# ----- read user inputs for installation parameters
function readInput(){
    INPUT_VALUE=""
    echo "Please provides the following parameter values. (Enter q to quit)"
    while [ "$INPUT_VALUE" != "q" ]
    do  
        echo "Namespace [$APPS_NAMESPACE]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            APPS_NAMESPACE="$INPUT_VALUE"
        fi

        echo "RHSSO Namespace [$RHSSO_NAMESPACE]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            RHSSO_NAMESPACE="$INPUT_VALUE"
        fi

        echo "Apps Domain Name [$APP_DOMAIN_NAME]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            APP_DOMAIN_NAME=$INPUT_VALUE
        fi

        echo "Kafka Cluster Name [$KAFKA_CLUSTER_NAME]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            KAFKA_CLUSTER_NAME=$INPUT_VALUE
        fi
        
        echo "Slack API URL [$STRIMZI_SLACKAPI_URL]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            STRIMZI_SLACKAPI_URL=$INPUT_VALUE
        fi

        echo "Slack Channel [$STRIMZI_SLACK_CHANNEL]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            STRIMZI_SLACK_CHANNEL=$INPUT_VALUE
        fi

        INPUT_VALUE="q"
    done
}

# --- 
# Installing Fuse Console for namespaces
# Pre-requistions:
#   1. You have the cluster admin role for the OpenShift cluster.
#   2. The Fuse Console image stream (along with the other Fuse image streams) are installed, as described in Installing Fuse imagestreams and templates on the OpenShift 4.x server.
#      https://access.redhat.com/documentation/en-us/red_hat_fuse/7.6/html-single/fuse_on_openshift_guide/index#install-fuse-on-openshift4
# ---
function deployFuseConsole(){
    
    echo
    echo "--> Deploying Fuse Console ... "
    echo

    mkdir ../tmp/fuseconsole

    echo
    echo "Generating required client certs ... "
    echo

    oc get secrets/signing-key -n openshift-service-ca -o "jsonpath={.data['tls\.crt']}" | base64 --decode > ../tmp/fuseconsole/ca.crt
    oc get secrets/signing-key -n openshift-service-ca -o "jsonpath={.data['tls\.key']}" | base64 --decode > ../tmp/fuseconsole/ca.key

    openssl genrsa -out ../tmp/fuseconsole/server.key 2048

    openssl req -new -key ../tmp/fuseconsole/server.key -out ../tmp/fuseconsole/server.csr -config ../templates/fuseconsole/csr.conf

    openssl x509 -req -in ../tmp/fuseconsole/server.csr -CA ../tmp/fuseconsole/ca.crt -CAkey ../tmp/fuseconsole/ca.key -CAcreateserial -out ../tmp/fuseconsole/server.crt -days 10000 -extensions v3_ext -extfile ../templates/fuseconsole/csr.conf
    
    echo
    echo "Using ../templates/fuseconsole/fuse-console-namespace-os4.json ..."
    echo

    FUSE_APP_NAME=$(cat ../templates/fuseconsole/fuse-console-namespace-os4.json |  jq -r '.parameters[] | select(.name=="APP_NAME") | .value')
    FUSE_APP_VERSION=$(cat ../templates/fuseconsole/fuse-console-namespace-os4.json |  jq -r '.parameters[] | select(.name=="APP_VERSION") | .value')
    
    echo
    echo "Using Fuse Console APP_NAME:$FUSE_APP_NAME, FUSE_APP_VERSION:$FUSE_APP_VERSION ..."
    echo

    echo
    echo "Creating secret $FUSE_APP_NAME-tls-proxying ..."
    echo

    oc -n $APPS_NAMESPACE create secret tls $FUSE_APP_NAME-tls-proxying --cert ../tmp/fuseconsole/server.crt --key ../tmp/fuseconsole/server.key

    echo
    echo "Importing fuse-console:$FUSE_APP_VERSION image if not available ..."
    echo
    oc import-image fuse7/fuse7-console:$FUSE_APP_VERSION --from=registry.redhat.io/fuse7/fuse-console:1.6 --confirm -n openshift

    echo
    echo "Creating Fuse Console Apps ..."
    echo
    oc new-app -f ../templates/fuseconsole/fuse-console-namespace-os4.json -n $APPS_NAMESPACE

}

function deployNConfigurePrometheus(){

    echo
    echo "--> Deploying Prometheus for Kafka ... "
    echo
    
    echo
    echo "Creating the secret ... "
    echo
    oc create secret generic additional-scrape-configs --from-file=../templates/kafka/metrics/prometheus-additional-properties/prometheus-additional.yaml  -n $APPS_NAMESPACE

    echo
    echo "Deploying Prometheus ... "
    echo
    
    mkdir -p ../tmp/kafka/metrics/prometheus-install
    cp ../templates/kafka/metrics/prometheus-install/strimzi-service-monitor.yaml ../tmp/kafka/metrics/prometheus-install/strimzi-service-monitor.yaml
    cp ../templates/kafka/metrics/prometheus-install/prometheus.yaml ../tmp/kafka/metrics/prometheus-install/prometheus.yaml
    
    sed -i -e "s/paygate/$APPS_NAMESPACE/" ../tmp/kafka/metrics/prometheus-install/strimzi-service-monitor.yaml
    sed -i -e "s/paygate/$APPS_NAMESPACE/" ../tmp/kafka/metrics/prometheus-install/prometheus.yaml

    oc apply -f ../tmp/kafka/metrics/prometheus-install/strimzi-service-monitor.yaml  -n $APPS_NAMESPACE
    oc apply -f ../templates/kafka/metrics/prometheus-install/prometheus-rules.yaml  -n $APPS_NAMESPACE
    oc apply -f ../tmp/kafka/metrics/prometheus-install/prometheus.yaml  -n $APPS_NAMESPACE

    echo
    echo "--> Deploying AlertManager ... "
    echo

    echo
    echo "Creating secret ... "
    echo
    mkdir -p ../tmp/kafka/metrics/prometheus-alertmanager-config
    cp ../templates/kafka/metrics/prometheus-alertmanager-config/alert-manager-config.yaml ../tmp/kafka/metrics/prometheus-alertmanager-config/alert-manager-config.yaml
    sed -i -e "s/slack_api_url:.*/slack_api_url: $STRIMZI_SLACKAPI_URL/" ../tmp/kafka/metrics/prometheus-alertmanager-config/alert-manager-config.yaml
    sed -i -e "s/channel:.*/channel: $STRIMZI_SLACK_CHANNEL/" ../tmp/kafka/metrics/prometheus-alertmanager-config/alert-manager-config.yaml
    
    oc create secret generic alertmanager-alertmanager --from-file=alertmanager.yaml=../tmp/kafka/metrics/prometheus-alertmanager-config/alert-manager-config.yaml -n $APPS_NAMESPACE

    echo
    echo "Deploying AlertManager ... "
    echo
    oc apply -f ../templates/kafka/metrics/prometheus-install/alert-manager.yaml -n $APPS_NAMESPACE

    echo
    echo "--> Deploying Grafana ... "
    echo
    oc apply -f ../templates/kafka/metrics/grafana-install/grafana.yaml -n $APPS_NAMESPACE

    oc expose service grafana  -n $APPS_NAMESPACE

    # --- updating the Grafana Dashboard json with the correct ocp project name.
    cp ../templates/grafana/grafanadashboard_common_payment_gateway_overview.json ../templates/grafana/grafanadashboard_payment_gateway_overview.json
    sed -i -e "s/paygate/$APPS_NAMESPACE/g" ../templates/grafana/grafanadashboard_payment_gateway_overview.json

    echo
    echo "Please refer to the following for guide on enabling the Grafana dashboard for Kafka ... "
    echo
    echo "https://access.redhat.com/documentation/en-us/red_hat_amq/7.6/html-single/using_amq_streams_on_openshift/index#proc-metrics-grafana-dashboard-str"
    echo
}

function printCmdUsage(){
    echo 
    echo "This is the Payment Gateway demo installer."
    echo
    echo "Command usage: ./deployDemo.sh <options>"
    echo 
    echo "-h       Show this help."
    echo "-i       Install the default demo / basic demo."
    echo 
}

function printHelp(){
    printCmdUsage
    echo "The following is a quick list of the installer requirements:"
    echo "    * The required OpenShift projects are created."
    echo "    * keytool is installed on your system."
    echo "    * openssl is installed on your system."
    echo "    * jq is installed on your system."
    echo "    * Kafka Operator is installed on OpenShift."
    echo "    * Promethues Operator is installed in the same namespace as the demo apps. This is only required if Promethues is to be installed."
    echo "    * An Openshift user with cluster-admin role."
    echo
    echo "Refer to the following website for the complete guide ..."
    echo "https://github.com/chengkuangan/pgwdemo"
    echo
}

function processArguments(){

    if [ $# -eq 0 ]; then
        printCmdUsage
        exit 0
    fi

    while (( "$#" )); do
      if [ "$1" == "-h" ]; then
        printHelp
        exit 0
      # Proceed to install
      elif [ "$1" == "-i" ]; then
        PROCEED_INSTALL="yes"
        shift
      else
        echo "Unknown argument: $1"
        printCmdUsage
        exit 0
      fi
      shift
    done
}

# ------
# Install only the basic demo
# The basic demo is without the following:
#    - Prometheus
# ------
function installBaseDemo(){
    #createNamespaces
    deployKafka
    deployCRMDB
    deployKafkaConnect
    deployAccountService
    deployCreditService
    deployEventCorrelator
    deployAccountProfile
    deployCustomerCamelService
    deployCustomerUI
    postDeployCreditResponseMongoDBConfig
    configureKafkaConnect4CRMDB
    importSampleData
    deployRHSSO
    deployFuseConsole
}

function showConfirmToProceed(){
    echo
    echo "Press ENTER (OR Ctrl-C to cancel) to proceed..."
    read bc
}

processArguments $@
init
readInput
preRequisitionCheck
printVariables

if [ "$PROCEED_INSTALL" != "yes" ]; then
    removeTempDirs
    exit 0
fi

echo "Please ensure you had installed the following Operator before proceed ..."
echo
echo "   * Red Hat AMQ Streams Operator"
echo "   * Prometheus Operator"
echo
showConfirmToProceed
installBaseDemo
deployNConfigurePrometheus
removeTempDirs