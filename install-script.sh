#!/bin/sh
#
#     This file is part of the Squashtest platform.
#     Copyright (C) 2010 - 2012 Henix, henix.fr
#
#     See the NOTICE file distributed with this work for additional
#     information regarding copyright ownership.
#
#     This is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Lesser General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     this software is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Lesser General Public License for more details.
#
#     You should have received a copy of the GNU Lesser General Public License
#     along with this software.  If not, see <http://www.gnu.org/licenses/>.
#

cd /opt/squash-tm/bin

########## SEARCHING FOR LINKED DB SERVER ############
##########      PREPARING CONNECTION      ############

# If we're linked to a DB server and have credentials already, let's use them. (searching for "MYSQL" or "POSTGRES" in the container env varibles)
echo 'looking for existing  db : mysql?' | env | grep MYSQL
MYSQL_EXIST=$?
echo 'still looking for existing db : postgres?' | env | grep POSTGRE
POSTRESQL_EXIST=$?

####### MYSQL #######
# In the case a MYSQL server was linked to the container, here are the values of local variables using for connection
if [ $MYSQL_EXIST -eq 0 ]; then
	echo 'MYSQL is up '
   sleep 5
    DB_TYPE='mysql'
    DB_HOST=${DB_HOST:-'mysql'}
    DB_PORT='3306'
    DB_DRIVER='org.gjt.mm.mysql.Driver'
    DB_USERNAME=${MYSQL_ENV_MYSQL_USER:-'root'}
    
    if [ "${DB_USERNAME}" = 'root' ]; then
        DB_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}
    fi
    
    DB_PASSWORD=${MYSQL_ENV_MYSQL_PASSWORD}
    DB_NAME=${MYSQL_ENV_MYSQL_DATABASE:-'squashtm'}

    if [ -z "$DB_PASSWORD" ]; then
        echo >&2 'error: missing required DB_PASSWORD environment variable'
        echo >&2 '  Did you forget to -e DB_PASSWORD=... ?'
        echo >&2
        echo >&2 '  (Also of interest might be DB_USERNAME and DB_NAME.)'
        exit 1
    fi
    
####### POSTGRESQL ########
# In the case a POSTGRESQL server was linked to the container, here are the values of local variables using for connection
elif [ $POSTRESQL_EXIST -eq 0 ]; then
	echo 'POSTGRESQL is up'
     sleep 5
    DB_TYPE='postgresql'
    DB_HOST=${DB_HOST:-'postgres'}
    DB_PORT='5432'
    DB_DRIVER='org.postgresql.Driver'
    DB_USERNAME=${POSTGRES_ENV_POSTGRES_USER:-'root'}

    if [ "${DB_USERNAME}" = 'postgres' ]; then
        DB_PASSWORD=${DB_PASSWORD:-'postgres'}
    fi

    DB_PASSWORD=${POSTGRES_ENV_POSTGRES_PASSWORD}
    DB_NAME=${POSTGRES_ENV_POSTGRES_DB:-'squashtm'}

    if [ -z "$DB_PASSWORD" ]; then
        echo >&2 'error: missing required DB_PASSWORD environment variable'
        echo >&2 '  Did you forget to -e DB_PASSWORD=... ?'
        echo >&2
        echo >&2 '  (Also of interest might be DB_USERNAME and DB_NAME.)'
        exit 1
    fi

####### H2 ########
# In the case no db server was linked to the container, Squash will use the default embedded H2 db. Here are the local variables using for connection
else 
    echo 'There is no database linked to Squash... This squash instance will use the default embedded h2 DB. This is OK for test purpose only'.
    echo 'TO USE SQUASH TM IN PRODUCTION, IT IS RECOMMENDED TO USE EITHER MYSQL OR POSTGESQL DATABASE' 
    DB_TYPE='h2'
    DB_HOST='..'
    DB_USERNAME='sa'
    DB_PASSWORD='sa'
    DB_NAME='squashtm'
    DB_URL='jdbc:h2:../data/squash-tm'
fi



########## CHECKING SQUASH TM DB EXISTENCE ###########
##########       EXECUTING DB SCRIPTS      ###########

#### MySQL DB ####
if [[ "${DB_TYPE}" = "mysql" ]]; then
    echo 'Using MysQL'
    DB_PORT=${DB_PORT:-'3306'}
    DB_URL="jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/$DB_NAME"
    until nc -zv -w 5 ${DB_HOST} ${DB_PORT}; do echo waiting for mysql; sleep 2; done;
    #If database doesn't exist, executing full install sql script for the right version (latest)
    if ! mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "SELECT 1 FROM information_schema.tables WHERE table_schema = '$DB_NAME' AND table_name = 'ISSUE';" | grep 1 ; then
        echo 'Initializing MySQL database'
        mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME < /opt/squash-tm/database-scripts/mysql-full-install-version-$SQUASH_TM_VERSION.RELEASE.sql
    #If database exist, checking version match. If it doesn't, executing db upgrade sql script 
    else
        echo 'Database already initialized... Is an upgrade necessary ? '
        #Upgrading DB? 
        VERSION_SQUASH=$(echo $SQUASH_TM_VERSION | grep -Eo "[1-9]\.[0-9]{2}")
	      VERSION_DB=$(mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "SELECT * FROM CORE_CONFIG WHERE STR_KEY='squashtest.tm.database.version';" | grep -Eo "[1-9]\.[0-9]{2}")
	      echo "Major version of Squash TM : $VERSION_SQUASH"
	      echo "Major version of existing linked DB: $VERSION_DB"
	      if [ ${VERSION_DB/./} -lt ${VERSION_SQUASH/./} ] ; then 
	          echo "Upgrading Squash TM MySQL DB to ${SQUASH_TM_VERSION}..."
		        mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME < /opt/squash-tm/database-scripts/mysql-upgrade-to-$VERSION_SQUASH.0.sql	
	          if [ $? -ne 0 ] ; then
		            echo "ERROR: Failed to upgrade MySQL (code $? )"
		            exit_code=2
	          else
		            echo "Squash TM MySQL DB upgraded !"
            fi                
	      fi
    fi    
         
#### POSTGRESQL DB ####
elif [[ "${DB_TYPE}" = "postgresql" ]]; then
    echo 'Using PostgreSQL'
    DB_PORT=${DB_PORT:-'5432'}
    DB_URL="jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/$DB_NAME"
    until nc -zv -w 5 ${DB_HOST} ${DB_PORT}; do echo waiting for postgresql; sleep 2; done;
    #If database doesn't exist, executing full install sql script for the right version (latest)
    if ! psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST/$DB_NAME -c "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'issue';" | grep 1 ; then
        echo 'Initializing PostgreSQL database'
        psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:${DB_PORT}/$DB_NAME -f /opt/squash-tm/database-scripts/postgresql-full-install-version-$SQUASH_TM_VERSION.RELEASE.sql
    #If database exist, checking version match. If it doesn't, executing db upgrade sql script
    else
        echo 'Database already initialized... Is an upgrade necessary ? '
        #Upgrading DB? 
        VERSION_SQUASH=$(echo $SQUASH_TM_VERSION | grep -Eo "[1-9]\.[0-9]{2}")
	      VERSION_DB=$(psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST/$DB_NAME -c "SELECT * FROM CORE_CONFIG WHERE STR_KEY='squashtest.tm.database.version';" | grep -Eo "[1-9]\.[0-9]{2}")
	      echo "Major version of Squash TM : $VERSION_SQUASH"
	      echo "Major version of existing linked DB: $VERSION_DB"
	      if [ ${VERSION_DB/./} -lt ${VERSION_SQUASH/./} ] ; then 
	          echo "Upgrading Squash TM PostgreSQL DB to ${SQUASH_TM_VERSION}..."
		        psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST/$DB_NAME < /opt/squash-tm/database-scripts/postgresql-upgrade-to-$VERSION_SQUASH.0.sql	
	          if [ $? -ne 0 ] ; then
		            echo "ERROR: Failed to upgrade PostgreSQL (code $? )"
		            exit_code=2
	          else
		            echo "Squash TM PostgreSQL DB upgraded !"
            fi                
	      fi
    fi         
fi


########## MODIFYING DB CONNECTION VARIABLES ###########
##########    IN SQUASH-TM STARTUP SCRIPT    ###########

if [[ "$DB_TYPE" != "h2" ]]; then
	echo 'Modifying startup.sh'
	cd /opt/squash-tm/bin
	sed -i "s/DB_TYPE=h2/DB_TYPE=$DB_TYPE/" startup.sh &&\
	sed -i "s?jdbc:h2:../data/squash-tm?$DB_URL?" startup.sh &&\
	sed -i "s/USERNAME=sa/USERNAME=$DB_USERNAME/" startup.sh &&\
	sed -i "s/PASSWORD=sa/PASSWORD=$DB_PASSWORD/" startup.sh

fi

# Fix Jasper Report problem in Docker
sed -i.bck '/exec java/i DAEMON_ARGS="-Djava.awt.headless=true ${DAEMON_ARGS}"' startup.sh

# Starting up squash-tm
cd /opt/squash-tm/bin && ./startup.sh
