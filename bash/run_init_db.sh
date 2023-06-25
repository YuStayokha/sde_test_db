#!/bin/bash

#Скачивание образа postgres 14.2 , запуск контейнера с именем pg_test , разворачивание DB + монтирование шар
docker run --name pg_test -e POSTGRES_USER=test_sde -e POSTGRES_PASSWORD=@sde_password012 -e POSTGRES_DB=demo -d -p 6543:5432 -v C:/beel/sde_test_db/sql:/mnt/sql -v C:/beel/sde_test_db/sql/init_db:/docker-entrypoint-initdb.d postgres:14.2 && sleep 20 && docker container start pg_test && sleep 20 && docker exec pg_test psql -U test_sde -d demo -f //docker-entrypoint-initdb.d/demo.sql

