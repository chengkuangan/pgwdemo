#!/bin/bash

########################################################################################################################
### 
### Installation script for Payment Gateway Demo.
### Contributed By: CK Gan (chgan@redhat.com)
### Complete demo setup guide is at https://github.com/chengkuangan/pgwdemo
### 
########################################################################################################################

APPS_NAMESPACE="paygate-apps"
APPS_PROJECT_DISPLAYNAME="Payment Gateway"
ISTIO_SYSTEM_NAMESPACE="paygate-istio-system"
THREESCALE_NAMESPACE="paygate-3scale"
RHSSO_NAMESPACE="paygate-rhsso"
PROJ_TOOLS_NAME="paygate-tools"
KAFKA_NAMESPACE="paygate-strimzi"
OBSERVER_NAMESPACE="paygate-observer"

KAFKA_CLUSTER_NAME="kafka-cluster"
KAFKA_BOOTSTRAP_SERVER=$KAFKA_CLUSTER_NAME-kafka-bootstrap.$KAFKA_NAMESPACE.svc:9092
KAFKA_BOOTSTRAP_SERVER_TLS=$KAFKA_CLUSTER_NAME-kafka-bootstrap.$KAFKA_NAMESPACE.svc:9093

APP_DOMAIN_NAME=`oc get ingresses.config.openshift.io cluster -o json 2>/dev/null | jq -r .spec.domain` 
[ ! "$APP_DOMAIN_NAME" ] && APP_DOMAIN_NAME="apps.ocpcluster1.gemsdemolab.com"  # default value if ingresses does not exist


OC_USER=""

NPM_MIRROR=""
MAVEN_MIRROR_URL=""

SSO_APPNAME="sso"
SSO_ADMIN_USERNAME="admin"
SSO_ADMIN_PASSWORD="password"

STRIMZI_SLACKAPI_URL="https:\/\/ssa-mr19696.slack.com"
STRIMZI_SLACK_CHANNEL="#paygate-strimzi"

PROCEED_INSTALL="no"
REINSTALL_RHSSO="no"
RESTART_DEPLOYMENT="no"

ERROR_MESSAGES=""

# Command prompt text colours
RED='\033[1;31m'
NC='\033[0m' # No Colour
GREEN='\033[1;32m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'

############################################################################################################################################
# START: Common Functions
############################################################################################################################################

# ----- read user inputs for installation parameters
function readInput(){
    INPUT_VALUE=""
    echo
    printHeader "Please provides the following parameter values. (Enter q to quit)"
    echo
    while [ "$INPUT_VALUE" != "q" ]
    do  
        #if [ "$REINSTALL_RHSSO" != "yes" ]; then
        printf "Namespace [$APPS_NAMESPACE]:"
        read INPUT_VALUE
        if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
            APPS_NAMESPACE="$INPUT_VALUE"
        fi

        if [ "$INPUT_VALUE" = "q" ]; then
            removeTempDirs
            exit 0
        fi
        #fi  

        if [ "$RESTART_DEPLOYMENT" != "yes" ]; then
            printf "Strimzi Namespace [$KAFKA_NAMESPACE]:"
            read INPUT_VALUE
            if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
                KAFKA_NAMESPACE="$INPUT_VALUE"
            fi

            if [ "$INPUT_VALUE" = "q" ]; then
                removeTempDirs
                exit 0
            fi
            printf "RHSSO Namespace [$RHSSO_NAMESPACE]:"
            read INPUT_VALUE
            if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
                RHSSO_NAMESPACE="$INPUT_VALUE"
            fi

            if [ "$INPUT_VALUE" = "q" ]; then
                removeTempDirs
                exit 0
            fi

            printf "Istio System Namespace [$ISTIO_SYSTEM_NAMESPACE]:"
            read INPUT_VALUE
            if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
                ISTIO_SYSTEM_NAMESPACE="$INPUT_VALUE"
            fi

            if [ "$INPUT_VALUE" = "q" ]; then
                removeTempDirs
                exit 0
            fi

            printf "Observer Namespace [$OBSERVER_NAMESPACE]:"
            read INPUT_VALUE
            if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
                OBSERVER_NAMESPACE="$INPUT_VALUE"
            fi

            if [ "$INPUT_VALUE" = "q" ]; then
                removeTempDirs
                exit 0
            fi

            printf "Apps Domain Name [$APP_DOMAIN_NAME]:"
            read INPUT_VALUE
            if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
                APP_DOMAIN_NAME=$INPUT_VALUE
            fi

            if [ "$INPUT_VALUE" = "q" ]; then
                removeTempDirs
                exit 0
            fi
        fi

        #if [ "$REINSTALL_RHSSO" != "yes" ] && [ "$RESTART_DEPLOYMENT" != "yes" ]; then
        #    printf "Istio System Namespace [$ISTIO_SYSTEM_NAMESPACE]:"
        #    read INPUT_VALUE
        #    if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
        #        ISTIO_SYSTEM_NAMESPACE="$INPUT_VALUE"
        #    fi
#
 #           if [ "$INPUT_VALUE" = "q" ]; then
  #              removeTempDirs
   #             exit 0
    #        fi
     #   fi

        #if [ "$RESTART_DEPLOYMENT" != "yes" ]; then
        #    printf "Apps Domain Name [$APP_DOMAIN_NAME]:"
        #    read INPUT_VALUE
        #    if [ "$INPUT_VALUE" != "" ] && [ "$INPUT_VALUE" != "q" ]; then
        #        APP_DOMAIN_NAME=$INPUT_VALUE
        #    fi
#
        #    if [ "$INPUT_VALUE" = "q" ]; then
        #        removeTempDirs
        #        exit 0
        #    fi
        #fi

        
        INPUT_VALUE="q"
    done
}


function printCmdUsage(){
    echo 
    echo "This is the Payment Gateway demo installer."
    echo
    echo "Command usage: ./deployDemo.sh <options>"
    echo 
    echo "-h            Show this help."
    echo "-i            Install the default demo / basic demo."
    echo "-sso          Reinstall RHSSO."
    echo "-rd           Restart deployments. "
    echo "              Use this command parameter to restart all deployments."
    echo 
}

function printHelp(){
    printCmdUsage
    printHeader "The following is a quick list of the installer requirements:"
    echo
    echo "    * The required OpenShift projects are created."
    echo "    * keytool is installed on your system."
    echo "    * openssl is installed on your system."
    echo "    * jq is installed on your system."
    echo "    * An Openshift user with cluster-admin role."
    echo "    * The following Operators are installed:"
    echo "      - Red Hat AMQ Streams"
    echo "      - Red Hat ServiceMesh"
    echo "      - Jaeger"
    echo "      - Kiali"
    echo "      - ElasticSearch"
    echo
    printHeader "Refer to the following website for the complete and updated guide ..."
    echo
    printLink "https://github.com/chengkuangan/pgwdemo"
    echo
}

function printResult(){
    echo 
    echo "=============================================================================================================="
    echo 
    printTitle "PAYMENT GATEWAY INSTALLATION COMPLETED !!!"
    echo
    if [ ! -z "$ERROR_MESSAGES" ]; then
        printError "Seems like the deployment completed with some errors. Please refer the following:"
        printf $ERROR_MESSAGES
    fi
    echo
    printHeader " You can access to the demo at the following URLs:"
    echo
    echo -e " * Customer UI - ${GREEN}http://customer-ui-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME ${NC}"
    echo "   Account:"
    echo "      - john/password"
    echo "      - jenny/password"
    echo
    echo "   Account: Use the openshift username to login."
    echo
    echo -e " * RHSSO Admin Console - ${GREEN}http://sso-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME${NC} or ${GREEN}https://secure-sso-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME${NC}"
    echo "   Account:"
    echo "      - $SSO_ADMIN_USERNAME/$SSO_ADMIN_PASSWORD"
    echo
    echo " * ServiceMesh Services: "
    echo -e "   Kiali - ${GREEN}https://kiali-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME${NC}"
    echo -e "   Prometheus - ${GREEN}https://prometheus-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME${NC}"
    echo -e "   Grafana - ${GREEN}https://grafana-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME${NC}"
    echo "      Account: Use the openshift username to login"
    echo
    printHeader " Additional Notes:"
    echo " -----------------"
    echo
    echo -e " * There might be situation some of the applications shown on Kiali console with ${RED}Missing Sidecar${NC}. " 
    echo "   This is because the applications deployed before ServiceMesh is ready. Please run the following command "
    echo "   to redeploy the applications."
    echo 
    printCommand "      ./deployDemo.sh -rd"
    echo
    #echo -e " * The installed RHSSO is ${RED}ephemeral${NC}. The configurations will be lost if the POD restarted or the OpenShift server restarted. "
    #echo "   If this happens, please delete the RHSSO project and run the following command to recreate the RHSSO:"
    #echo 
    #printCommand "      ./deployDemo.sh -sso"
    #echo
    echo -e " * Please logon to Service Mesh Grafana admin console and import the samples dashboards as per the following:"
    echo "    ../templates/grafana/temp/paygate-overview-grafana-dashboard.json"
    echo
    echo -e " * Please logon to Grafana admin console @ $OBSERVER_NAMESPACE project and import the samples dashboards as per the following:"
    echo "    ../templates/grafana/strimzi-all-in-one-grafana-dashboard.json"
    echo
    echo -e "   Grafana - ${GREEN}https://grafana-$OBSERVER_NAMESPACE.$APP_DOMAIN_NAME${NC}"
    echo
    echo " * The default Kiali installed  by Operator excludes DeploymentConfig from the dashboard. Please following the guide below to enable DeploymentConfig:"
    echo "    https://access.redhat.com/solutions/5359141"
    echo "=============================================================================================================="
    echo
}

function init(){
    
    set echo off
    OC_USER="$(oc whoami)"
    set echo on
    
    if [ $? -ne 0 ] || [ "$OC_USER" = "" ]; then
        echo
        printWarning "Please login to Openshift before proceed ..."
        echo
        exit 0
    fi
    echo
    printHeader "--> Creating temporary directory ../tmp"
    mkdir ../tmp

    printHeader "--> Create OpenShift required projects if not already created"

    oc new-project $APPS_NAMESPACE
    oc new-project $ISTIO_SYSTEM_NAMESPACE
    oc new-project $RHSSO_NAMESPACE
    oc new-project $KAFKA_NAMESPACE
    oc new-project $OBSERVER_NAMESPACE

}

function printTitle(){
    HEADER=$1
    echo -e "${RED}$HEADER${NC}"
}

function printHeader(){
    HEADER=$1
    echo -e "${YELLOW}$HEADER${NC}"
}

function printLink(){
    LINK=$1
    echo -e "${GREEN}$LINK${NC}"
}

function printCommand(){
    COMMAND=$1
    echo -e "${GREEN}$COMMAND${NC}"
}

function printWarning(){
    WARNING=$1
    echo -e "${RED}$WARNING${NC}"
}

function printError(){
    ERROR=$1
    echo -e "${RED}$ERROR${NC}"
}

function printVariables(){
    echo 
    printHeader "The following is the parameters enter..."
    echo
    echo "OC_USER = $OC_USER"
    echo "APP_DOMAIN_NAME = $APP_DOMAIN_NAME"
    echo "APPS_NAMESPACE = $APPS_NAMESPACE"
    echo "APPS_PROJECT_DISPLAYNAME = $APPS_PROJECT_DISPLAYNAME"
    echo "RHSSO_NAMESPACE = $RHSSO_NAMESPACE"
    echo "ISTIO_SYSTEM_NAMESPACE = $ISTIO_SYSTEM_NAMESPACE"
    echo "KAFKA_NAMESPACE = $KAFKA_NAMESPACE"
    echo "OBSERVER_NAMESPACE = $OBSERVER_NAMESPACE"
    echo "KAFKA_CLUSTER_NAME = $KAFKA_CLUSTER_NAME"
    echo "SSO_ADMIN_USERNAME = $SSO_ADMIN_USERNAME"
    echo "SSO_ADMIN_PASSWORD = $SSO_ADMIN_PASSWORD"
    echo "SSO_APPNAME = $SSO_APPNAME"
    echo

    printWarning "Please increase the limit range configured at OpenShift if there is any. Remove the limit range if possible. Deployment will failed if some of the components cannot request resources more than allowed."
    
    echo

    printWarning "Please wait and ensure that all required Operators are ready in the projects before proceed!"

    echo
}

function preRequisitionCheck(){
    
    echo 
    printHeader "--> Checking on pre-requisitions ..."
    echo
    
    # checking whether jq command tool is installed.
    hash jq
    
    if [ $? -ne 0 ]; then
        echo
        printWarning "You will required jq command line JSON processor ... "
        echo
        echo "Please download and install the command line tool from here ... https://stedolan.github.io/jq/"
        echo
        removeTempDirs
        exit 0
    fi

    oc project $RHSSO_NAMESPACE
    
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have the following OpenShift projects created before proceed ... "
        echo
        echo "   * $RHSSO_NAMESPACE"
        echo "   * $APPS_NAMESPACE"
        echo "   * $ISTIO_SYSTEM_NAMESPACE"
        echo
        removeTempDirs
        exit 0
    fi

    oc project $APPS_NAMESPACE

    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have the following OpenShift projects created before proceed ... "
        echo
        echo "   * $RHSSO_NAMESPACE"
        echo "   * $APPS_NAMESPACE"
        echo "   * $ISTIO_SYSTEM_NAMESPACE"
        echo
        removeTempDirs
        exit 0
    fi

    oc project $ISTIO_SYSTEM_NAMESPACE
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have the following OpenShift projects created before proceed ... "
        echo
        echo "   * $RHSSO_NAMESPACE"
        echo "   * $APPS_NAMESPACE"
        echo "   * $ISTIO_SYSTEM_NAMESPACE"
        echo
        removeTempDirs
        exit 0
    fi

    oc get sub --all-namespaces -o custom-columns=NAME:.metadata.name | grep 'elastic'
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have installed the following Operators ... "
        echo
        echo "   * Elasticsearch"
        echo
        removeTempDirs
        exit 0
    fi

    oc get sub --all-namespaces -o custom-columns=NAME:.metadata.name | grep 'jaeger'
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have installed the following Operators ... "
        echo
        echo "   * Jaeger"
        echo
        removeTempDirs
        exit 0
    fi

    oc get sub --all-namespaces -o custom-columns=NAME:.metadata.name | grep 'kiali'
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have installed the following Operators ... "
        echo
        echo "   * Kiali"
        echo
        removeTempDirs
        exit 0
    fi

    oc get sub --all-namespaces -o custom-columns=NAME:.metadata.name | grep 'servicemesh\|service-mesh'
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have installed the following Operators ... "
        echo
        echo "   * ServiceMesh"
        echo
        removeTempDirs
        exit 0
    fi

    oc get sub --all-namespaces -o custom-columns=NAME:.metadata.name | grep 'amq-streams'
    if [ $? -ne 0 ]; then
        echo
        printWarning "Please ensure you have installed the following Operators ... "
        echo
        echo "   * AMQ Streams"
        echo
        removeTempDirs
        exit 0
    fi
}

function catchError(){
    if [ $? -ne 0 ]; then
        echo
        printError "Error running the above command ... "
        echo
        printError $1
        ERROR_MESSAGES="$ERROR_MESSAGES\n$1\n"
        #removeTempDirs
        #exit 0
    fi
}

function showConfirmToProceed(){
    echo
    printWarning "Press ENTER (OR Ctrl-C to cancel) to proceed..."
    read bc
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
      #elif [ "$1" == "-sso" ]; then
      #  REINSTALL_RHSSO="yes"
      #  shift  
      elif [ "$1" == "-rd" ]; then
        RESTART_DEPLOYMENT="yes"
        shift    
      else
        echo "Unknown argument: $1"
        printCmdUsage
        exit 0
      fi
      shift
    done
}

# ----- Remove all tmp content after completed.
function removeTempDirs(){
    echo
    printHeader "--> Removing ../tmp directory ... "
    echo
    rm -rf ../tmp
}


function configurePromGrafana(){
    
    TARGET_NAMESPACE=$1

    echo
    printHeader "--> Configure Prometheus for $TARGET_NAMESPACE namespace ... "
    echo

    mkdir -p ../tmp/observer/
    
    echo
    echo "Creating the cluster-monitoring-config configmap for namespaces ... "
    echo
    oc apply -f ../templates/observer/cluster-monitoring-config.yaml  -n openshift-monitoring
    
    catchError "Error creating clustermonitoring-config configmap."

    echo
    echo "Configuring Grafana for $TARGET_NAMESPACE namespace ... "
    echo
    
    cp ../templates/observer/grafana-sa.yaml ../tmp/observer/grafana-sa.yaml
    catchError "Error copying ../templates/observer/grafana-sa.yaml."

    sed -i -e "s/myproject/$TARGET_NAMESPACE/" ../tmp/observer/grafana-sa.yaml
    catchError "Error sed ../tmp/observer/grafana-sa.yaml."

    oc apply -f ../tmp/observer/grafana-sa.yaml -n $TARGET_NAMESPACE
    catchError "Error oc applying ../tmp/observer/grafana-sa.yaml."

    GRAFANA_SA_TOKEN="$(oc serviceaccounts get-token grafana-serviceaccount -n $TARGET_NAMESPACE)"
    echo "GRAFANA_SA_TOKEN=$GRAFANA_SA_TOKEN"
    catchError "Error get-token for grafana-serviceaccount"

    cp ../templates/observer/datasource.yaml ../tmp/observer/datasource.yaml
    catchError "Error copying ../templates/observer/datasource.yaml."

    sed -i -e "s/GRAFANA-ACCESS-TOKEN/$GRAFANA_SA_TOKEN/" ../tmp/observer/datasource.yaml
    catchError "Error sed for ../tmp/observer/datasource.yaml"

    oc create configmap grafana-config --from-file=../tmp/observer/datasource.yaml -n $TARGET_NAMESPACE
    catchError "Error create configmap grafana-config"

    oc apply -f ../templates/observer/grafana.yaml -n $TARGET_NAMESPACE
    catchError "Error applying ../templates/observer/grafana.yaml"

    oc create route edge grafana --service=grafana -n $TARGET_NAMESPACE
    catchError "Error create route edge grafana"
}

function configurePrometheus4Kafka(){

    echo
    printHeader "--> Configuring Prometheus for Kafka in namespace $KAFKA_NAMESPACE ... "
    echo
    
    mkdir -p ../tmp/observer/

    cp ../templates/observer/strimzi-pod-monitor.yaml ../tmp/observer/strimzi-pod-monitor.yaml
    catchError "Error copying ../templates/observer/strimzi-pod-monitor.yaml"
    sed -i -e "s/myproject/$KAFKA_NAMESPACE/" ../tmp/observer/strimzi-pod-monitor.yaml
    catchError "Error sed ../tmp/observer/strimzi-pod-monitor.yaml"
    oc apply -f ../tmp/observer/strimzi-pod-monitor.yaml  -n $KAFKA_NAMESPACE
    catchError "Error applying ../tmp/observer/strimzi-pod-monitor.yaml"
    oc apply -f ../templates/observer/prometheus-rules.yaml  -n $KAFKA_NAMESPACE
    catchError "Error applyting ../templates/observer/prometheus-rules.yaml"

}


function updateGrafanaDashboards(){
    echo 
    printHeader "--> Updating Grafana Dashboard templates ... "
    echo
    # --- updating the Grafana Dashboard json with the correct ocp project name.
    # --- using a different template for Service Mesh Grafana
    ## cp ../templates/grafana/grafanadashboard_common_payment_gateway_overview.json ../templates/grafana/grafanadashboard_payment_gateway_overview.json
    mkdir -p ../templates/grafana/temp

    cp -f ../templates/grafana/paygate-overview-grafana-dashboard.json ../templates/grafana/temp/paygate-overview-grafana-dashboard.json
    sed -i -e "s/paygate-apps/$APPS_NAMESPACE/g" ../templates/grafana/temp/paygate-overview-grafana-dashboard.json

}


############################################################################################################################################
# END: Common Functions
############################################################################################################################################

############################################################################################################################################
# START: Deployment Functions
############################################################################################################################################

function deployKafka(){
    echo
    printHeader "--> Installing Strimzi ... "
    echo
    mkdir -p ../tmp/kafka
    catchError "Error: Deploy Kafka -> Error creating directory ../tmp/kafka"
    cp ../templates/kafka/kafka-persistent.yaml ../tmp/kafka/kafka-persistent.yaml
    catchError "Error: Deploy Kafka -> Error copying template ../templates/kafka/kafka-persistent.yaml > ../tmp/kafka/kafka-persistent.yaml"
    sed -i -e "s/paygate/$KAFKA_NAMESPACE/" ../tmp/kafka/kafka-persistent.yaml
    catchError "Error: Deploy Kafka -> Error changing template value (../tmp/kafka/kafka-persistent.yaml)"
    echo 
    printHeader "--> Deploying AMQ Streams (Strimzi) Cluster now ... Using ../tmp/kafka/kafka-persistent.yaml"
    oc apply -f ../tmp/kafka/kafka-persistent.yaml -n $KAFKA_NAMESPACE
    catchError "Error: Deploy Kafka -> Error running 'oc apply -f ../tmp/kafka/kafka-persistent.yaml -n $KAFKA_NAMESPACE' "
    echo
}

## --- Deploy CreditResponse MongoDB
function deployCRMDB(){
    echo 
    printHeader "--> Deploying Credit Response Mongodb database ..."
    echo
    # TODO enable prometheus for mongodb
    oc new-app -f ../templates/apps/creditresponse-mongodb-deployment-template.yaml -n $APPS_NAMESPACE
    catchError "Error: Deploy Credit Response MongoDB (CRMB) : Error running 'oc new-app -f ../templates/apps/creditresponse-mongodb-deployment-template.yaml -n $APPS_NAMESPACE' "
}

# ----- Deploy Kafka Connect
function deployKafkaConnect(){
    echo
    printHeader "--> Deploy Kafka Connect ..."
    echo
    echo "Waiting for Kafka to be ready ..."
    KAFKA_POD_READY="$(oc get pod $KAFKA_CLUSTER_NAME-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $KAFKA_NAMESPACE)"
    while [ $? -ne 0 ]
        do
            echo "$KAFKA_CLUSTER_NAME-kafka-0 is not created yet ... Waiting ... "
            sleep 10
            KAFKA_POD_READY="$(oc get pod $KAFKA_CLUSTER_NAME-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $KAFKA_NAMESPACE)"
        done
    echo "POD: $KAFKA_CLUSTER_NAME-kafka-0, ready: $KAFKA_POD_READY"
    # oc get pod pg-kafka-cluster-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n pg
    while [ "$KAFKA_POD_READY" = "false" ]
        do  
            sleep 10
            KAFKA_POD_READY="$(oc get pod $KAFKA_CLUSTER_NAME-kafka-0 -o custom-columns=Ready:status.containerStatuses[0].ready --no-headers -n $KAFKA_NAMESPACE)"
            echo "POD: $KAFKA_CLUSTER_NAME-kafka-0, ready: $KAFKA_POD_READY"
        done
    mkdir -p ../tmp/crmdb
    
    echo "Creating Secret for Strimzi CA Cert ..."
    cp ../templates/apps/strimzi-cert-secret.yaml ../tmp/crmdb/strimzi-cert-secret.yaml
    STRIMZI_CACERT=$(oc get secret kafka-cluster-cluster-ca-cert -o "jsonpath={.data['ca\.crt']}" -n $KAFKA_NAMESPACE)
    sed -i -e "s/STRIMZI_CA_CRT/$STRIMZI_CACERT/" ../tmp/crmdb/strimzi-cert-secret.yaml
    oc apply -f ../tmp/crmdb/strimzi-cert-secret.yaml -n $APPS_NAMESPACE

    echo "Deploying CRMDB Kafka Connect container ..."
    cp ../templates/apps/crmdb-kafka-connect.yaml ../tmp/crmdb/crmdb-kafka-connect.yaml
    # Kafka connect must use TLS connection to Kafka server
    sed -i -e "s/kafka-cluster-kafka-bootstrap:9093/$KAFKA_BOOTSTRAP_SERVER_TLS/" ../tmp/crmdb/crmdb-kafka-connect.yaml
    oc apply -f ../tmp/crmdb/crmdb-kafka-connect.yaml -n $APPS_NAMESPACE
    catchError "Error: Deploy Kafka Connect : Error running 'oc apply -f ../tmp/crmdb/crmdb-kafka-connect.yaml -n $APPS_NAMESPACE' "

}

# ----- Deploy RHSSO and configure the necessary realms and users.
function deployRHSSO(){
    echo 
    printHeader "--> Deploy RHSSO ..."
    echo

    #oc new-project $RHSSO_NAMESPACE
    oc policy add-role-to-user view system:serviceaccount:$RHSSO_NAMESPACE:default -n $RHSSO_NAMESPACE

    mkdir -p ../tmp/sso
    echo
    echo "Generating required certs and keystores for RHSSO ..."
    echo
    openssl req -new -newkey rsa:4096 -x509 -keyout ../tmp/sso/xpaas.key -out ../tmp/sso/xpaas.crt -passout pass:openshift -days 365 -subj "/CN=xpaas-sso-demo.ca"
    keytool -genkeypair -keyalg RSA -keysize 2048 -dname "CN=secure-sso-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME" -alias jboss -storepass mykeystorepass -keystore ../tmp/sso/keystore.jks
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
    
    #oc new-app --template=sso73-x509-postgresql-persistent -n $RHSSO_NAMESPACE \
    #-p APPLICATION_NAME=$SSO_APPNAME \
    #-p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME \
    #-p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD

    #oc new-app --template=sso73-https -n $RHSSO_NAMESPACE \
    oc new-app --template=sso74-postgresql-persistent -n $RHSSO_NAMESPACE \
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
    
    catchError "Error: Deploy RHSSO : Error running 'oc new-app --template=sso74-postgresql-persistent ... ' "

    #oc new-app --template=sso73-x509-postgresql-persistent -n $RHSSO_NAMESPACE -p APPLICATION_NAME=$SSO_APPNAME -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD -p POSTGRESQL_IMAGE_STREAM_TAG=latest
    #oc new-app --template=sso73-postgresql-persistent -n $RHSSO_NAMESPACE -p APPLICATION_NAME=$SSO_APPNAME -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD -p POSTGRESQL_IMAGE_STREAM_TAG=latest
    #oc new-app --template=sso73-https -n $RHSSO_NAMESPACE -p APPLICATION_NAME=$SSO_APPNAME -p SSO_ADMIN_USERNAME=$SSO_ADMIN_USERNAME -p SSO_ADMIN_PASSWORD=$SSO_ADMIN_PASSWORD
    
    echo
    echo "Configure RHSSO PaymentGateway Realms..."
    echo
    
    #SSO_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $RHSSO_NAMESPACE | grep $SSO_APPNAME-[a-z0-9] | grep -v $SSO_APPNAME-[a-z0-9]-deploy)"
    SSO_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $RHSSO_NAMESPACE | grep $SSO_APPNAME-.* | grep -v $SSO_APPNAME-[a-z0-9]-deploy | grep -v $SSO_APPNAME-postgresql-.*)"
    # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n rhsso | grep sso.[a-z0-9].[^deploy]
    echo "Waiting for POD to to be created ... POD Name: $SSO_POD_NAME"
    while [ "$SSO_POD_NAME" = "" ]
        do
            sleep 10
            #SSO_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $RHSSO_NAMESPACE | grep $SSO_APPNAME-[a-z0-9] | grep -v $SSO_APPNAME-[a-z0-9]-deploy)"
            SSO_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $RHSSO_NAMESPACE | grep $SSO_APPNAME-.* | grep -v $SSO_APPNAME-[a-z0-9]-deploy | grep -v $SSO_APPNAME-postgresql-.*)"
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
    
    cp ../templates/rhsso/paymentgateway-realm.json ../tmp/sso/
    # --- Changing the CustomerAccount client URI and URL to reflect to the correct route protected by istio.
    sed -i -e "s/http:\/\/customeraccount:3000/http:\/\/customer-ui-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME/" ../tmp/sso/paymentgateway-realm.json
    #sed -i -e "s/http:\/\/customeraccount:3000/http:\/\/customer-ui-$APPS_NAMESPACE.$APP_DOMAIN_NAME/" ../tmp/sso/paymentgateway-realm.json

    oc cp ../tmp/sso/paymentgateway-realm.json $SSO_POD_NAME:/tmp/ -n $RHSSO_NAMESPACE
    # -- calling the REST API inside of the port. Not calling from outside because the self-signed cert will cause problem.
    MESSAGE=$(oc -n $RHSSO_NAMESPACE exec $SSO_POD_NAME -- curl -k -X POST "http://sso:8080/auth/realms/master/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=$SSO_ADMIN_USERNAME" -d "password=$SSO_ADMIN_PASSWORD" -d "grant_type=password" -d "client_id=admin-cli")
    if [[ $MESSAGE == *"error_code"* ]] ; then
        echo
        printWarning "Error getting access token from RHSSO at Pod:$SSO_POD_NAME. Please check the log for more details."
    else
        TOKEN=$(echo $MESSAGE | jq -r '.access_token')
        MESSAGE=$(oc -n $RHSSO_NAMESPACE exec $SSO_POD_NAME -- curl -k -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @/tmp/paymentgateway-realm.json http://sso:8080/auth/admin/realms)
        if [[ $MESSAGE == *"error_code"* ]] ; then
            echo
            printWarning "Error importing PaymentGateway Realm. Using $SSO_POD_NAME:/tmp/paymentgateway-realm.json"
        fi
    fi

    # --- updating the master sslRequired to 'none'
    #REALM=$(curl -k -v -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" http://sso-paygate-rhsso.apps.cluster-spore-7e54.spore-7e54.sandbox1254.opentlc.com/auth/admin/realms/master)
    RHSSO_MASTER_REALM=$(oc -n $RHSSO_NAMESPACE exec $SSO_POD_NAME -- curl -k -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" http://sso:8080/auth/admin/realms/master)
    RHSSO_MASTER_REALM=$(echo $RHSSO_MASTER_REALM | jq '.sslRequired  = "none"')
    oc -n $RHSSO_NAMESPACE exec $SSO_POD_NAME -- curl -k -X PUT "http://sso:8080/auth/admin/realms/master" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$RHSSO_MASTER_REALM"

}

# ----- Build and deploy Account Service
function deployAccountService(){
    echo
    printHeader "--> Deploying Account Service and DB Service ... "
    echo

    echo
    echo "Starts building image ... "
    echo

    mkdir -p ../tmp/accountservice && cp -r ../sc/AccountService/* ../tmp/accountservice/ && rm -f ../tmp/accountservice/README.adoc && rm -rf ../tmp/accountservice/target
    
    oc new-build -n $APPS_NAMESPACE -e MAVEN_MIRROR_URL=$MAVEN_MIRROR_URL -i redhat-openjdk18-openshift:1.4 \
    --labels='app=accountservice,app-group=accountservice' --name='accountservice' --to='accountservice:latest' --binary=true
    
    oc start-build accountservice --from-file=../tmp/accountservice/ -n $APPS_NAMESPACE --wait

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/apps/accountservice-templates.yaml -p APP_NAMESPACE=$APPS_NAMESPACE
    # TODO enable prometheus for mongodb
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    #oc annotate --overwrite svc accountservice prometheus.io/scrape='true' prometheus.io/port='8080' prometheus.io/path=/actuator/prometheus -n $APPS_NAMESPACE

}

# ----- Build and deploy Credit Service
function deployCreditService(){
    echo
    printHeader "--> Deploying Credit Services ... "
    echo

    echo
    echo "Starts building image ... "
    echo
    mkdir -p ../tmp/creditservice && cp -r ../sc/Credit/* ../tmp/creditservice/ && rm -f ../tmp/creditservice/README.adoc && rm -rf ../tmp/creditservice/node_modules
    oc new-build -n $APPS_NAMESPACE -e NPM_MIRROR=$NPM_MIRROR -i nodejs:latest --labels='app=creditservice,app-group=creditservice' --name='creditservice' --to='creditservice:latest' --binary=true
    oc start-build creditservice --from-file=../tmp/creditservice/ -n $APPS_NAMESPACE --wait

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true \
    -f ../templates/apps/creditservice-template.json \
    -p KAFKA_BOOTSTRAP_SERVER=$KAFKA_BOOTSTRAP_SERVER \
    -p APP_NAMESPACE=$APPS_NAMESPACE
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    #oc annotate --overwrite svc creditservice prometheus.io/scrape='true' prometheus.io/port='8080' -n $APPS_NAMESPACE

}

# ----- Deploy Event Correlator service
function deployEventCorrelator(){

    echo
    printHeader "--> Deploying Event Correlator Services ... "
    echo

    echo
    echo "Starts building image ... "
    echo

    mkdir -p ../tmp/eventcorrelator && cp -r ../sc/EventCorrelator/* ../tmp/eventcorrelator/ && rm -f ../tmp/eventcorrelator/README.adoc && rm -rf ../tmp/eventcorrelator/target
    oc new-build -n $APPS_NAMESPACE -e MAVEN_MIRROR_URL=$MAVEN_MIRROR_URL -i redhat-openjdk18-openshift:1.4 --labels='app=event-correlator,app-group=event-correlator' \
    --name='event-correlator' --to='event-correlator:latest' --binary=true

    oc start-build event-correlator --from-file=../tmp/eventcorrelator/ -n $APPS_NAMESPACE --wait

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/apps/eventcorrelator-templates.yaml \
    -p KAFKA_BOOTSTRAP_SERVER=$KAFKA_BOOTSTRAP_SERVER \
    -p ACCOUNT_BALANCE_POST_URL=http://accountservice:8080/ws/pg/balance \
    -p ACCOUNT_BALANCE_GET_URL=http://accountservice:8080/ws/pg/balance \
    -p APP_NAMESPACE=$APPS_NAMESPACE
   
    # oc new-app -n pg --allow-missing-imagestream-tags=true -f ../templates/eventcorrelator-templates.yaml -p KAFKA_BOOTSTRAP_SERVER=pg-kafka-cluster-kafka-bootstrap:9093 -p ACCOUNT_BALANCE_POST_URL=http://accountbalance:8080/ws/pg/balance -p ACCOUNT_BALANCE_GET_URL=http://accountbalance:8080/ws/pg/balance
 
}

# ----- Build and deploy Account Profile
function deployAccountProfile(){

    echo
    printHeader "--> Deploying Account Profile services ... "
    echo
    
    echo
    echo "Starting building image ... "
    echo
    mkdir -p ../tmp/accountprofile && cp -r ../sc/AccountProfile/* ../tmp/accountprofile/ && rm -f ../tmp/accountprofile/README.adoc && rm -rf ../tmp/accountprofile/target
    oc new-build -n $APPS_NAMESPACE -e MAVEN_MIRROR_URL=$MAVEN_MIRROR_URL -i redhat-openjdk18-openshift:1.4 --labels='app=accountprofile,app-group=accountprofile' \
    --name='accountprofile' --to='accountprofile:latest' --binary=true

    oc start-build accountprofile --from-file=../tmp/accountprofile/ -n $APPS_NAMESPACE --wait

    # oc apply -n $APPS_NAMESPACE -f ../templates/accountprofile-buildconfig.yaml -p NPM_MIRROR=http://nexus3-paygate-tools.apps.cluster-spore-7e54.spore-7e54.sandbox1254.opentlc.com/repository/maven-all-public/
    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true -f ../templates/apps/accountprofile-templates.yaml -p APP_NAMESPACE=$APPS_NAMESPACE
    # TODO enable prometheus for mongodb
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    #oc annotate --overwrite svc accountprofile prometheus.io/scrape='true' prometheus.io/port='8080' prometheus.io/path=/actuator/prometheus -n $APPS_NAMESPACE

}

# ----- Build and deploy CustomerService, which is a Camel Service.
function deployCustomerCamelService(){

    echo
    printHeader "--> Deploying Customer Camel Services ... "
    echo 

    
    mkdir -p ../tmp/customerservice && cp -r ../sc/CustomerService/* ../tmp/customerservice/ && rm -f ../tmp/customerservice/README.adoc && rm -rf ../tmp/customerservice/target
    cd ../tmp/customerservice

    # The OCP Deployment settings is in fabric8/deployment.xml
    oc project $APPS_NAMESPACE
    #mvn clean install fabric8:build -DMAVEN_MIRROR_URL=$MAVEN_MIRROR_URL
    mvn clean install fabric8:build
    catchError "Error: Deploy Customer Camel Services : Error running 'mvn clean install fabric8:build' "

    oc new-app -n $APPS_NAMESPACE -f ../../templates/apps/customerservice-template.yaml
    
    catchError "Error: Deploy Customer Camel Services : Error running 'oc new-app -n $APPS_NAMESPACE -f ../../templates/apps/customerservice-template.yaml' "

    #oc annotate --overwrite svc customerservice prometheus.io/scrape='true' prometheus.io/port='9779'

    #mvn clean install fabric8:deploy -Dfabric8.deploy.createExternalUrls=true fabric8:log 
    #mvn clean install fabric8:deploy -Dfabric8.openshift.generateRoute=false -Dopenshift.namespace=$APPS_NAMESPACE
    #mvn clean install fabric8:deploy -Dfabric8.openshift.generateRoute=false -Dfabric8.mode=kubernetes
    #mvn -DCUST_PROFILE_HOST=accountprofile -DCUST_PROFILE_PORT=8080 -DACC_SERVICE_HOST=accountservice -DACC_SERVICE_PORT=8080 -DSERVICE_PORT=8080 clean install fabric8:deploy -Dfabric8.deploy.createExternalUrls=true fabric8:log 

    cd ../../bin
}

# ----- Build and deploy Customer UI
function deployCustomerUI(){
    echo
    printHeader "--> Deploying Customer UI ... "
    echo

    echo
    echo "Starts building image ... "
    echo

    mkdir -p ../tmp/customerui && cp -r ../sc/CustomerUI/* ../tmp/customerui/  && rm -f ../tmp/customerui/README.adoc && rm -rf ../tmp/customerui/node_modules
    oc new-build -n $APPS_NAMESPACE -e NPM_MIRROR=$NPM_MIRROR -i nodejs:latest --labels='app=customer-ui,app-group=customer-ui' --name='customer-ui' --to='customer-ui:latest' --binary=true
    sed -i -e "s/http:\/\/localhost:8080\/auth/http:\/\/$SSO_APPNAME-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME\/auth/" ../tmp/customerui/keycloak.json
    oc start-build customer-ui --from-file=../tmp/customerui/ -n $APPS_NAMESPACE --wait

    oc new-app -n $APPS_NAMESPACE --allow-missing-imagestream-tags=true \
    -f ../templates/apps/customerui-template.json \
    -p RHSSO_URL=http://$SSO_APPNAME-$RHSSO_NAMESPACE.$APP_DOMAIN_NAME \
    -p APP_NAMESPACE=$APPS_NAMESPACE
    #-p CREDIT_API_URL=http://creditservice-chgan-payment-gateway.apps.ocpcluster1.gemsdemolab.com/ws/pg/credits \
    
    # --- Have to explicitly annotate the service to enable prometheus, setting in templates not working for unknown reason.
    #oc annotate --overwrite svc customer-ui prometheus.io/scrape='true' prometheus.io/port='8080' -n $APPS_NAMESPACE
    
}

function deployPaymentHistoryService(){
    echo 
    printHeader "--> Deploying Payment History Service ..."
    echo
    
    echo
    echo "Building and deploying payment-history-service ... "
    echo
    
    oc project $APPS_NAMESPACE

    mkdir -p ../tmp/payment-history-service && cp -r ../sc/PaymentHistoryService/* ../tmp/payment-history-service/ \
    && cp -r ../sc/PaymentHistoryService/.mvn ../tmp/payment-history-service/ && rm -rf ../tmp/payment-history-service/target

    cd ../tmp/payment-history-service
    
    ./mvnw clean package -DskipTests \
    -Dquarkus.container-image.group=$APPS_NAMESPACE \
    -Dquarkus.kubernetes-client.trust-certs=true -Dquarkus.kubernetes.deploy=true \
    -Dquarkus.openshift.env-vars.mongodb-dbname.value=creditresponse \
    -Dquarkus.openshift.env-vars.mongodb-collection.value=response \
    -Dquarkus.openshift.env-vars.mongodb-connection-string.value=mongodb://creditresponse:creditresponse@creditresponse:27017 \
    -Dquarkus.openshift.env-vars.account-profile-get-endpoint.value=http://accountprofile:8080/ws/pg/account \
    -Dquarkus.openshift.name=payment-history-service  \
    -Dquarkus.openshift.labels.app=payment-history-service \
    -Dquarkus.openshift.labels.app-group=payment-history-service \
    -Dquarkus.kubernetes.namespace=$APPS_NAMESPACE

    oc patch dc payment-history-service -p '"spec": {"template": { "metadata": { "annotations": { "sidecar.istio.io/inject": "true" }, "labels": { "version": "v1" } } } }' -n $APPS_NAMESPACE
    
    cd ../../bin

}

function installServiceMesh(){
    echo 
    printHeader "--> Installing the Service Mesh ..."
    echo
    # Updating with istio system namespace
    mkdir -p ../tmp/istio
    cp ../templates/istio/istio-installation.yaml ../tmp/istio/istio-installation.yaml
    sed -i -e "s/namespace:.*/namespace: $ISTIO_SYSTEM_NAMESPACE/" ../tmp/istio/istio-installation.yaml
    # Install the istio system
    oc create -n $ISTIO_SYSTEM_NAMESPACE -f ../tmp/istio/istio-installation.yaml
    # Updating namespace member templates.
    cp ../templates/istio/servicemeshmemberroll.yaml ../tmp/istio/servicemeshmemberroll.yaml
    sed -i -e "s/paygate/$APPS_NAMESPACE/" ../tmp/istio/servicemeshmemberroll.yaml
    sed -i -e "s/namespace:.*/namespace: $ISTIO_SYSTEM_NAMESPACE/" ../tmp/istio/servicemeshmemberroll.yaml
    # Create the istio members
    oc create -n $ISTIO_SYSTEM_NAMESPACE -f ../tmp/istio/servicemeshmemberroll.yaml

}

# --- Deploying Kafka Topic Viewer ...
# --- Web Apps to view real-time messages in Kafka Topics.
function deployKafkaTopicViewer(){
    echo 
    printHeader "--> Deploying Kafka Topic Viewer ..."
    echo
    
    echo
    echo "Building and deploying credit-viewer ... "
    echo
    
    #oc project $APPS_NAMESPACE
    oc project $OBSERVER_NAMESPACE

    mkdir -p ../tmp/creditviewer && cp -r ../sc/KafkaTopicViewer/* ../tmp/creditviewer/ \
    && cp -r ../sc/KafkaTopicViewer/.mvn ../tmp/creditviewer/ && rm -rf ../tmp/creditviewer/target

    sed -i -e "s/kafka-topic-viewer/credit-viewer/" ../tmp/creditviewer/pom.xml    # quarkus.container-image.name produces inconsistent outcome... have to manually change pom.xml

    cd ../tmp/creditviewer
    
    #-Dquarkus.container-image.name=credit-viewer \    # quarkus.container-image.name produces inconsistent outcome... have to manually change pom.xml
    ./mvnw clean package -DskipTests \
    -Dquarkus.container-image.group=$OBSERVER_NAMESPACE \
    -Dquarkus.kubernetes-client.trust-certs=true -Dquarkus.kubernetes.deploy=true \
    -Dquarkus.openshift.env-vars.kafka-bootstrap-servers.value=$KAFKA_BOOTSTRAP_SERVER \
    -Dquarkus.openshift.env-vars.kafka-topic.value=credit \
    "-Dquarkus.openshift.env-vars.ui-index-title.value=Payment Gateway - Kafka credit Topic Viewer" \
    -Dquarkus.openshift.env-vars.kafka-consumer-group-id.value=credit-viewer \
    -Dquarkus.openshift.name=credit-viewer \
    -Dquarkus.openshift.labels.app=credit-viewer \
    -Dquarkus.kubernetes.namespace=$OBSERVER_NAMESPACE
    catchError "Error deploying credit-viewer."

    echo
    echo "Building and deploying credit-response-viewer ... "
    echo

    cd ../../

    mkdir -p tmp/creditresponseviewer && cp -r sc/KafkaTopicViewer/* tmp/creditresponseviewer/ \
    && cp -r sc/KafkaTopicViewer/.mvn tmp/creditresponseviewer/ && rm -rf tmp/creditresponseviewer/target
    cd tmp/creditresponseviewer

    sed -i -e "s/kafka-topic-viewer/credit-response-viewer/" pom.xml    # quarkus.container-image.name produces inconsistent outcome... have to manually change pom.xml
    
    # -Dquarkus.container-image.name=credit-response-viewer \       # quarkus.container-image.name produces inconsistent outcome... have to manually change pom.xml
    ./mvnw clean package -DskipTests \
    -Dquarkus.container-image.group=$OBSERVER_NAMESPACE \
    -Dquarkus.kubernetes-client.trust-certs=true -Dquarkus.kubernetes.deploy=true \
    -Dquarkus.openshift.env-vars.kafka-bootstrap-servers.value=$KAFKA_BOOTSTRAP_SERVER \
    -Dquarkus.openshift.env-vars.kafka-topic.value=credit-response \
    "-Dquarkus.openshift.env-vars.ui-index-title.value=Payment Gateway - Kafka credit-response Topic Viewer" \
    -Dquarkus.openshift.env-vars.kafka-consumer-group-id.value=credit-response-viewer \
    -Dquarkus.openshift.name=credit-response-viewer \
    -Dquarkus.openshift.labels.app=credit-response-viewer \
    -Dquarkus.kubernetes.namespace=$OBSERVER_NAMESPACE
    catchError "Error deploying credit-response-viewer."

    cd ../../bin

}

# Implicitly restarting all deployment.
# This is only needed when after initial deployment, the istio proxy container has not been injected due to the application started earlier before the istio service is ready.
function restartDeployment(){
    if [ "$RESTART_DEPLOYMENT" = "yes" ]; then
        echo 
        printHeader "Restarting Payment Gateway application deployments ..."
        echo
        showConfirmToProceed
        oc rollout restart deployment/accountprofile -n $APPS_NAMESPACE
        oc rollout restart deployment/accountprofile-mongodb -n $APPS_NAMESPACE
        oc rollout restart deployment/accountservice -n $APPS_NAMESPACE
        oc rollout restart deployment/accountservice-mongodb -n $APPS_NAMESPACE
        oc rollout restart deployment/creditresponse -n $APPS_NAMESPACE
        oc rollout restart deployment/creditservice -n $APPS_NAMESPACE
        oc rollout restart deployment/customer-ui -n $APPS_NAMESPACE
        oc rollout restart deployment/customerservice -n $APPS_NAMESPACE
        oc rollout restart deployment/mongodb-connect-cluster-connect -n $APPS_NAMESPACE
        oc rollout restart deployment/event-correlator -n $APPS_NAMESPACE
        oc rollout restart dc/payment-history-service -n $APPS_NAMESPACE
        exit 0
    fi
}

# ------
# Install only the basic demo
# ------
function installBaseDemo(){
    deployKafka
    deployCRMDB
    deployKafkaConnect
    deployAccountService
    deployCreditService
    deployEventCorrelator
    deployAccountProfile
    deployCustomerCamelService
    deployCustomerUI
    deployPaymentHistoryService
    postDeployCreditResponseMongoDBConfig
    configureKafkaConnect4CRMDB
    importSampleData
    deployRHSSO
}

################################################### Post Configurations ###################################################

function configureServiceMeshNetwork(){
    echo 
    printHeader "--> Configuring the Service Mesh Policy ..."
    echo
    
    cp ../templates/istio/istio-apps-routes.yaml ../tmp/istio/istio-apps-routes.yaml
    sed -i -e "s/host: customer-ui.*/host: customer-ui-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME/" ../tmp/istio/istio-apps-routes.yaml
    oc apply -f ../tmp/istio/istio-apps-routes.yaml -n $ISTIO_SYSTEM_NAMESPACE
    
    # create gateway, vurtual service and destinationrule for customer-ui
    cp ../templates/istio/customer-ui-istio-network-config.yaml ../tmp/istio/customer-ui-istio-network-config.yaml
    sed -i -e "s/customer-ui-paygate-istio-system.*/customer-ui-$ISTIO_SYSTEM_NAMESPACE.$APP_DOMAIN_NAME\"/" ../tmp/istio/customer-ui-istio-network-config.yaml
    oc apply -f ../tmp/istio/customer-ui-istio-network-config.yaml -n $APPS_NAMESPACE

    # Patch istio-mesh network policy to allow network for PODs without label pgw-istio='true'
    # ---- not required anymore
    # oc patch networkpolicy istio-mesh -p '{"spec":{ "podSelector": {"matchLabels": { "pgw-istio": "true"}}}}' -n $APPS_NAMESPACE
}

## --- Perform necessary configuration after CreditResponse MongoDB POD is ready
function postDeployCreditResponseMongoDBConfig(){
    echo
    printHeader "--> Perfoming post deployment configuration ... "
    echo 
    echo "Patching Credit Response Mongodb ..."
    # CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep $CREDITRESPONSE_MONGODB_NAME.[a-z0-9].[^deploy])"
    CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep creditresponse-[a-z0-9] | grep -v creditresponse-[a-z0-9]-deploy)"
    # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n payment-gateway | grep creditresponse.[a-z0-9].[^deploy]
    while [ "$CREDITRESPONSE_MONGODB_POD_NAME" = "" ]
        do
            sleep 10
            # CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep $CREDITRESPONSE_MONGODB_NAME.[a-z0-9].[^deploy])"
            CREDITRESPONSE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep creditresponse-[a-z0-9] | grep  -v creditresponse-[a-z0-9]-deploy)"
            # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n payment-gateway | grep creditresponse-[a-z0-9]-.[^deploy]
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
    MONGODB_PATH="$(oc exec $CREDITRESPONSE_MONGODB_POD_NAME -c creditresponse -- ls /opt/rh)"
    oc cp ../templates/apps/crmdb.js -c creditresponse $CREDITRESPONSE_MONGODB_POD_NAME:/tmp/ -n $APPS_NAMESPACE
    catchError "Error: CRMB post configuration : Error running 'oc cp ./templates/apps/crmdb.js -c creditresponse $CREDITRESPONSE_MONGODB_POD_NAME:/tmp/ -n $APPS_NAMESPACE' "
    oc -n $APPS_NAMESPACE exec $CREDITRESPONSE_MONGODB_POD_NAME -c creditresponse -- scl enable $MONGODB_PATH -- mongo localhost:27017/admin /tmp/crmdb.js 
    catchError "Error: CRMB post configuration : Error running 'oc -n $APPS_NAMESPACE exec $CREDITRESPONSE_MONGODB_POD_NAME -c creditresponse -- scl enable $MONGODB_PATH -- mongo localhost:27017/admin /tmp/crmdb.js' "
}

# ----- Import the demo sample data into the respective database 
function importSampleData(){
   
    echo
    printHeader "--> Importing demo data for AccountService mongodb ... "
    echo

    ACCOUNT_SERVICE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountservice-mongodb-[a-z0-9] | grep -v accountservice-mongodb-[a-z0-9]-deploy)"
    echo "Waiting for POD to to be created ... POD Name: $ACCOUNT_SERVICE_MONGODB_POD_NAME"
    while [ "$ACCOUNT_SERVICE_MONGODB_POD_NAME" = "" ]
        do
            sleep 10
            ACCOUNT_SERVICE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountservice-mongodb-[a-z0-9] | grep -v accountservice-mongodb-[a-z0-9]-deploy)"
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
    MONGODB_PATH="$(oc exec $ACCOUNT_SERVICE_MONGODB_POD_NAME -c accountservice-mongodb -- ls /opt/rh)"
    oc -n $APPS_NAMESPACE -c accountservice-mongodb cp ../tmp/accountservice/src/main/resources/sampledata.json $ACCOUNT_SERVICE_MONGODB_POD_NAME:/tmp/ 
    oc -n $APPS_NAMESPACE exec $ACCOUNT_SERVICE_MONGODB_POD_NAME -c accountservice-mongodb  -- /opt/rh/$MONGODB_PATH/root/bin/mongoimport --db accountservice --collection balance --authenticationDatabase accountservice --username accountservice --password accountservice --drop --file /tmp/sampledata.json

    echo
    echo "Importing demo data for AccountProfile mongodb ... "
    echo

    ACCOUNT_PROFILE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountprofile-mongodb-[a-z0-9] | grep -v accountprofile-mongodb-[a-z0-9]-deploy)"
    echo "Waiting for POD to to be created ... POD Name: $ACCOUNT_PROFILE_MONGODB_POD_NAME"
    while [ "$ACCOUNT_PROFILE_MONGODB_POD_NAME" = "" ]
        do
            sleep 10
            ACCOUNT_PROFILE_MONGODB_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep accountprofile-mongodb-[a-z0-9] | grep -v accountprofile-mongodb-[a-z0-9]-deploy)"
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
    MONGODB_PATH="$(oc exec $ACCOUNT_PROFILE_MONGODB_POD_NAME -c accountprofile-mongodb -- ls /opt/rh)"
    oc -n $APPS_NAMESPACE -c accountprofile-mongodb cp ../tmp/accountprofile/src/main/resources/sampledata.json $ACCOUNT_PROFILE_MONGODB_POD_NAME:/tmp/
    oc -n $APPS_NAMESPACE exec $ACCOUNT_PROFILE_MONGODB_POD_NAME -c accountprofile-mongodb -- /opt/rh/$MONGODB_PATH/root/bin/mongoimport --db accountprofile --collection account --authenticationDatabase accountprofile --username accountprofile --password accountprofile --drop --file /tmp/sampledata.json
}   

## --- configure kafka connect for Credit Response mongodb
function configureKafkaConnect4CRMDB(){
    echo
    printHeader "--> Configuring Kafka Connect for CreditResponse Mongodb ... "
    echo
    #MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect)"
    MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect-[a-z0-9] | grep -v mongodb-connect-cluster-connect-[a-z0-9]-deploy)"
    # oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect)
    echo "Waiting for POD to to be created ... POD Name: $MONGODB_KAFKA_CONNECT_POD_NAME"
    while [ "$MONGODB_KAFKA_CONNECT_POD_NAME" = "" ]
        do
            sleep 10
            #MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect)"
            MONGODB_KAFKA_CONNECT_POD_NAME="$(oc get pods --no-headers -o custom-columns=NAME:.metadata.name -n $APPS_NAMESPACE | grep mongodb-connect-cluster-connect-[a-z0-9] | grep -v mongodb-connect-cluster-connect-[a-z0-9]-deploy)"
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
    oc cp ../templates/apps/connect-mongodb-sink.json $MONGODB_KAFKA_CONNECT_POD_NAME:/tmp/ -n $APPS_NAMESPACE
    MESSAGE=$(oc -n $APPS_NAMESPACE exec $MONGODB_KAFKA_CONNECT_POD_NAME -- curl -d @/tmp/connect-mongodb-sink.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors)
    if [[ $MESSAGE == *"error_code"* ]] ; then
        echo
        printError "Error configuring MongoDB Kafka Connect. Please check the log for more details. Please verify the content is correct in ./CreditResponseMongoDB/connect-mongodb-sink.json"
    fi
    echo
}


############################################################################################################################################
# END: Deployment Functions
############################################################################################################################################


############################################################################################################################################
### The process START here ...
############################################################################################################################################

PROCESS_START=$SECONDS

processArguments $@
readInput
restartDeployment   # redeployment of applications if -rd parameter is used.
init
preRequisitionCheck
printVariables

if [ "$PROCEED_INSTALL" != "yes" ]; then
    removeTempDirs
    exit 0
fi

showConfirmToProceed
installServiceMesh
installBaseDemo
configureServiceMeshNetwork
deployKafkaTopicViewer
configurePromGrafana $OBSERVER_NAMESPACE
configurePrometheus4Kafka
updateGrafanaDashboards
removeTempDirs
printResult

PROCESS_DURATION=$(( SECONDS - PROCESS_START ))
echo
printTitle "TOTAL time took to deploy: $(($PROCESS_DURATION/60)) minutes"
echo

############################################################################################################################################
### The process END here ...
############################################################################################################################################


















################################################################################################################################
#### @Deprecated 
################################################################################################################################

function deployNConfigurePrometheus(){

    echo
    printHeader "--> Deploying Prometheus and AlertManager for Kafka ... "
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
    echo "Deploying AlertManager ... "
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
    echo "Deploying Grafana ... "
    echo
    oc apply -f ../templates/kafka/metrics/grafana-install/grafana.yaml -n $APPS_NAMESPACE

    oc expose service grafana  -n $APPS_NAMESPACE

    # --- updating the Grafana Dashboard json with the correct ocp project name.
    # --- using a different template for Service Mesh Grafana
    ## cp ../templates/grafana/grafanadashboard_common_payment_gateway_overview.json ../templates/grafana/grafanadashboard_payment_gateway_overview.json
    cp ../templates/grafana/grafanadashboard_payment_gateway_overview_sm.json ../templates/grafana/grafanadashboard_payment_gateway_overview_sm.json
    sed -i -e "s/paygate/$APPS_NAMESPACE/g" ../templates/grafana/grafanadashboard_payment_gateway_overview_sm.json

    echo
    printHeader "Please refer to the following for guide on enabling the Grafana dashboard for Kafka ... "
    echo
    printLink "https://access.redhat.com/documentation/en-us/red_hat_amq/7.6/html-single/using_amq_streams_on_openshift/index#proc-metrics-grafana-dashboard-str"
    echo
}

function reinstallRHSSO(){
    if [ "$REINSTALL_RHSSO" = "yes" ]; then
        echo 
        printHeader "--> Reinstalling RHSSO ... "
        echo
        printWarning "If you are reusing the same namespace, please delete the existing namespace using \"oc delete project $RHSSO_NAMESPACE\" before proceed."
        showConfirmToProceed
        oc new-project $RHSSO_NAMESPACE
        deployRHSSO
        removeTempDirs
        exit 0
    fi
}

function install3Scale(){
    
    echo
    printHeader "--> Installing 3Scale ... "
    echo
    echo
    printHeader "Creating 3Scale namespace ... "
    echo
    oc new-project $THREESCALE_NAMESPACE
    echo
    printHeader "Creating 3Scale CRD ... "
    echo
    for i in `ls ../templates/3scale/crds/*_crd.yaml`; do oc create -f $i -n $THREESCALE_NAMESPACE; done
    echo
    printHeader "Creating 3Scale service account ... "
    echo
    oc create -f ../templates/3scale/service_account.yaml -n $THREESCALE_NAMESPACE
    echo
    printHeader "Creating 3Scale role ... "
    echo
    oc create -f ../templates/3scale/role.yaml -n $THREESCALE_NAMESPACE
    echo
    printHeader "Creating 3Scale role binding ... "
    echo
    oc create -f ../templates/3scale/role_binding.yaml -n $THREESCALE_NAMESPACE
    echo
    printHeader "Deploying 3Scale Operator ... "
    echo
    oc create -f ../templates/3scale/operator.yaml -n $THREESCALE_NAMESPACE

}

function deployKafkaExporter(){
    echo 
    printHeader "--> Deploy Kafka Prometheus Exporter ... "
    echo
    mkdir -p ../tmp/kafka/kafka-exporter
    cp ../templates/kafka/kafka-exporter/deployment.yaml ../tmp/kafka/kafka-exporter/deployment.yaml
    sed -i -e "s/paygate/$APPS_NAMESPACE/" ../tmp/kafka/kafka-exporter/deployment.yaml
    sed -i -e "s/kafka-cluster-kafka-bootstrap/$KAFKA_CLUSTER_NAME-kafka-bootstrap/" ../tmp/kafka/kafka-exporter/deployment.yaml
    oc create -f ../tmp/kafka/kafka-exporter/deployment.yaml -n $APPS_NAMESPACE
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
    printHeader "--> Deploying Fuse Console ... "
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

# Optional tools
function installNexus(){
    oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/nexus3-persistent-templates.yaml -n $PROJ_TOOLS_NAME
}
