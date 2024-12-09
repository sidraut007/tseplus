#!/bin/bash
TSE_HOME=/opt/pfxwebsigner

checkDB() {
    DBSTATUS=$(pg_isready -d $PG_TSEDB -h $DB_HOST -p $DB_PORT -U $PG_TSEDBUSER)
    status_code=$?
    echo "DB status $status_code"
    if [ $status_code -eq 0 ]; then
        PGPASSWORD=$PG_TSEDBPASSWORD psql -h $DB_HOST -p $DB_PORT -U $PG_TSEDBUSER -d $PG_TSEDB < /opt/pfxwebsigner/artifacts/db.sql
        pg_upgrade_status_code=$?
        echo "DB upgrade $pg_upgrade_status_code"
    fi
    return $status_code
}

startTse() {
    DBSTATUS=$(checkDB)
    while [ "$DBSTATUS" -eq "0" ];
    do
        DBSTATUS=$(checkDB)
        echo "DB status $DBSTATUS!"
        sleep 2
    done
    if [ ! -d "$TSE_HOME/bin/pfxsigner.sh" ]; then
        cd $TSE_HOME 
        echo "Starting TSE..."
        /bin/bash $TSE_HOME/bin/pfxsigner.sh start
    fi
}

initialize() {
    cd /opt
    unzip -P tc12#45^78 /pfxwebsigner-2.0.0.zip
    if [ -e "/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java" ]; then
        sed -i 's/JAVA_HOME=\/usr\/lib\/jvm\/java-8-oracle\/jre/JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64\/jre/' $TSE_HOME/bin/pfxsigner.sh
    else
        sed -i 's/JAVA_HOME=\/usr\/lib\/jvm\/java-8-oracle\/jre/JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-arm64\/jre/' $TSE_HOME/bin/pfxsigner.sh
    fi
    sed -i 's/ -jar / -Djava.net.preferIPv4Stack=true -jar /' $TSE_HOME/bin/pfxsigner.sh
    mkdir -p "$TSE_HOME/logs"
    mkdir -p "$TSE_HOME/dbdumps"
    startTse
}

upgrade() {
    echo "Upgrading..."
    cd /tmp
    rm -rf pfxwebsigner
    mkdir -p $TSE_HOME/backups
    rm -rf $TSE_HOME/backups/*
    unzip -P tc12#45^78 /pfxwebsigner-2.0.0.zip
    APPPRO2=$(md5sum  $TSE_HOME/application.properties)
    APPPRO1=$(md5sum  /tmp/pfxwebsigner/application.properties)
    if [ "$APPPRO2" != "$APPPRO1" ]; then
        cp $TSE_HOME/application.properties $TSE_HOME/backups/
        cp /tmp/pfxwebsigner/application.properties $TSE_HOME/
        echo "Prop updated."
    fi
    APPCS2=$(md5sum  $TSE_HOME/pfxsigner.jar)
    APPCS1=$(md5sum  /tmp/pfxwebsigner/pfxsigner.jar)
    if [ "$APPCS2" != "$APPCS1" ]; then
        mv $TSE_HOME/pfxsigner.jar $TSE_HOME/backups/
        mv $TSE_HOME/lib $TSE_HOME/backups/
        cp /tmp/pfxwebsigner/pfxsigner.jar $TSE_HOME/
        cp -r /tmp/pfxwebsigner/lib $TSE_HOME/
        echo "App updated."
    fi
}

################################################################################
if [ ! -d "$TSE_HOME" ]; then
    echo "Directory $TSE_HOME does not exist, creating it..."
    initialize
else
    echo "Directory $TSE_HOME exists, installing..."
    if [ ! -f "$TSE_HOME/pfxsigner.jar" ]; then
        echo "Resuming pending installation..."
        initialize
    else
        upgrade
        startTse
    fi
fi
