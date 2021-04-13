#!/bin/ash
cd /app

mkdir -p /var/log/panel/logs/ /var/log/supervisord/ /var/log/nginx/ /var/log/php7/ \
  && chmod 777 /var/log/panel/logs/ \
  && ln -s /var/log/panel/logs/ /app/storage/logs/

## check for .env file and generate app keys if missing
if [ -f /app/var/.env ]; then
  echo "external vars exist."
  rm -rf /app/.env
  ln -s /app/var/.env /app/
else
  echo "external vars don't exist."
  rm -rf /app/.env
  touch /app/var/.env

  ## manually generate a key because key generate --force fails
  if [ -z $APP_KEY ]; then
     echo -e "Generating key."
     APP_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
     echo -e "Generated app key: $APP_KEY"
     echo -e "APP_KEY=$APP_KEY" > /app/var/.env
  else
    echo -e "APP_KEY exists in environment, using that."
    echo -e "APP_KEY=$APP_KEY" > /app/var/.env
  fi

  ln -s /app/var/.env /app/
fi

echo "writing ssl config"
cp .github/docker/default_ssl.conf /etc/nginx/conf.d/default.conf
echo "updating ssl config for domain"
sed -i "s|<domain>|$(echo $APP_URL | sed 's~http[s]*://~~g')|g" /etc/nginx/conf.d/default.conf

## check for DB up before starting the panel
echo "Checking database status."
until nc -z -v -w30 $DB_HOST 3306
do
  echo "Waiting for database connection..."
  # wait for 1 seconds before check again
  sleep 1
done

## make sure the db is set up
echo -e "Migrating and Seeding D.B"
php artisan migrate --seed --force

## start cronjobs for the queue
echo -e "Starting cron jobs."
crond -L /var/log/crond -l 5

echo -e "Starting supervisord."
exec "$@"
