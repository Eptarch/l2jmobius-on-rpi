#!/bin/bash
# The script must abort on any error.
set -e

ENV_FILE=./.env
GEODATA_DIR=./services/l2jmobius/geodata
SRC_DIR=./services/l2jmobius/src

# Create needed directories if they don't exist yet
mkdir -p ./services/mariadb/data
mkdir -p ./services/phpmyadmin/config
mkdir -p ./services/l2jmobius/build/{game,libs,login}
mkdir -p ./services/l2jmobius/build/{game,login}/log

# Get DB name from server files and plant it into .env file.
if [ -f $SRC_DIR/dist/game/config/Server.ini ];
then
  MARIADB_DATABASE=$(sed -n '45p' $SRC_DIR/dist/game/config/Server.ini | grep -oP -m 1 "[A-Za-z0-9_]+?(?=\?)");
  sed -i "/^MARIADB_DATABASE/c\MARIADB_DATABASE=$MARIADB_DATABASE" $ENV_FILE;
else
  echo "ERR: Failed to locate $SRC_DIR/dist/game/config/Server.ini.
  Were server source files placed correctly?
  Hint: 'correctly' means that $SRC_DIR contains build.xml.

  Exiting.";
  exit 1;
fi

# Parse environmental variables from .env file.
if [ -f $ENV_FILE ];
then
  export $(grep -v '^#' $ENV_FILE | xargs -d '\n');
  for evar in $MARIADB_USER $MARIADB_PASSWORD $MARIADB_ROOT_PASSWORD $MARIADB_DATABASE
  do
    if [ -z ${evar+x} ];
    then
      echo "ERR: Parsing $ENV_FILE resulted in unset variable.
      Check if .env file is present and contains key=value pairs of
      MARIADB_USER=SOME_USER
      MARIADB_PASSWORD=SOME_PASSWORD
      MARIADB_ROOT_PASSWORD=SOME_ROOT_PASSWORD
      MARIADB_DATABASE=SOME_MARIADB_DATABASE_NAME_OR_EMPTY

      Exiting.";
      exit 1;
    fi
  done
else
  echo "ERR: Failed to locate $ENV_FILE.
  Please, check if it is present and not empty.

  Exiting.";
  exit 1;
fi

# Check if geodata file is where it should be.
if [ -n "$(find $GEODATA_DIR -prune -empty 2>/dev/null)" ];
then
  echo "ERR: Failed to locate geodata archive.
  Please place single geodata archive into $GEODATA_DIR

  Exiting.";
  exit 1;
fi

# Install MariaDB and PHPMyAdmin to control it.
docker compose up -d db phpmyadmin --build

# Make sure that dist/db_installer/sql exists.
if [ -n "$(find $SRC_DIR/dist/db_installer/sql/ -prune -empty 2>/dev/null)" ];
then
  echo "ERR: No sql directory present in $SRC_DIR/dist/db_installer/sql/
  Either server files were misplaced or they don't exist.

  Exiting.";
  exit 1;
fi

echo "MariaDB takes some time to initialize for the first time.
It usually takes anywhere from about 5 seconds to a few minutes."

# mysql "${db}" >/dev/null 2>&1 </dev/null
while ! docker exec l2jmobius_db mysql --user $MARIADB_USER --password=$MARIADB_PASSWORD "$MARIADB_DATABASE" >/dev/null 2>&1 </dev/null;
do
  echo "Waiting for MariaDB to initialize ..."
  sleep 1
done

# Truncate all tables. This will wipe all data.
docker exec -i l2jmobius_db sh -c "\
  mysqldump \
  --user $MARIADB_USER \
  --password=$MARIADB_PASSWORD \
  --add-drop-table \
  --no-data $MARIADB_DATABASE \
  | grep ^DROP \
  | mysql \
  --user $MARIADB_USER \
  --password=$MARIADB_PASSWORD \
  --database=$MARIADB_DATABASE"

# Import login server SQL files into db.
for SQLFILE in $SRC_DIR/dist/db_installer/sql/login/*;
do
  docker exec -i l2jmobius_db sh -c "\
    mysql \
    --user $MARIADB_USER \
    --password=$MARIADB_PASSWORD \
    --database=$MARIADB_DATABASE" < $SQLFILE;
done

# Import game server SQL files into db.
for SQLFILE in $SRC_DIR/dist/db_installer/sql/game/*;
do
  docker exec -i l2jmobius_db sh -c "\
    mysql \
    --user $MARIADB_USER \
    --password=$MARIADB_PASSWORD \
    --database=$MARIADB_DATABASE" < $SQLFILE;
done

# Build jars, copy files, bring all that together and start it.
docker compose up -d --build
echo "Removing the container that was used to build server JARs"
docker rm l2jmobius_builder

echo "Done! :)"
