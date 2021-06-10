db = connect("localhost:27017/admin");
db.auth('admin','creditresponse');
db = db.getSiblingDB('admin');
db.runCommand({createRole:"listDatabases",privileges:[{resource:{cluster:true}, actions:["listDatabases"]}],roles:[]});
db.createUser({
"user" : "creditresponse",
"pwd" : "creditresponse",
    "roles" : [
        {
            "role" : "listDatabases",
            "db" : "admin"
        },
        {
            "role" : "readWrite",
            "db" : "creditresponse"
        },
        {
            "role" : "read",
            "db" : "local"
        }
    ]
});