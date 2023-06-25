CREATE TABLE bookings.results (
	id int,
	response text
);

--1.Вывести максимальное количество человек в одном бронировании

INSERT INTO bookings.results
select 1 as id, max(t1.pass_count) as response from (
  select book_ref, count(passenger_id) as pass_count from tickets
     group by book_ref
  ) as t1;


--2.Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование

INSERT INTO bookings.results
select 2 as id, count(t2.book_ref) as response from (
select book_ref, count(passenger_id) as pass_count from tickets
group by book_ref
having count(passenger_id) > (select avg(t1.pass_count) as pass_avg from 
                                (select book_ref, count(passenger_id) as pass_count from tickets
                                  group by book_ref) t1)
) t2;


--3.Вывести количество бронирований, у которых состав пассажиров повторялся
-- два и более раза, среди бронирований с максимальным количеством людей (п.1)?

INSERT INTO bookings.results
select 3 as id, case when sum(t4.book_ref_count) is null then 0 else sum(t4.book_ref_count) end response from (
 select t3.pass_agg, count(t3.book_ref) as book_ref_count from (
   select t2.book_ref, string_agg(t2.passenger_id, '|') as pass_agg, count(t2.passenger_id) as pass_count from (
      select book_ref, passenger_id from tickets order by book_ref, passenger_id
   ) t2
   group by t2.book_ref
   having count(t2.passenger_id) = (select max(t1.pass_count) as pass_max from (
                                   select book_ref, count(passenger_id) as pass_count from tickets
                                   group by book_ref
                                 ) as t1)
 ) t3
 group by t3.pass_agg
 having count(t3.book_ref) >= 2
) t4;


--4.Вывести номера брони и контактную информацию по пассажирам в брони
--(passenger_id, passenger_name, contact_data) с количеством людей в брони = 3

INSERT INTO bookings.results
select 4 as id, concat_ws('|', book_ref, passenger_id, passenger_name, contact_data) as response from tickets
where book_ref in (
   select book_ref from tickets
   group by book_ref
   having count(passenger_id) = 3
   )
order by book_ref, passenger_id, passenger_name, contact_data;


--5.Вывести максимальное количество перелётов на бронь

INSERT INTO bookings.results
select 5 as id, max(t2.flight_count) as response from (
  select t1.book_ref, count(t1.flight_id) as flight_count from (
    select b.book_ref, tf.flight_id from bookings b 
    join tickets t on b.book_ref = t.book_ref
    join ticket_flights tf on t.ticket_no = tf.ticket_no
  ) t1
  group by t1.book_ref
) t2;


--6.Вывести максимальное количество перелётов на пассажира в одной брони

INSERT INTO bookings.results
select 6 as id, max(t2.flight_count) as response from (
  select t1.book_ref, t1.passenger_id, count(t1.flight_id) as flight_count from (
    select b.book_ref, t.passenger_id, tf.flight_id from bookings b 
    join tickets t on b.book_ref = t.book_ref
    join ticket_flights tf on t.ticket_no = tf.ticket_no
  ) t1
  group by t1.book_ref, t1.passenger_id
) t2;


--7.Вывести максимальное количество перелётов на пассажира

INSERT INTO bookings.results
select 7 as id, max(t2.flight_count) as response from (
  select t1.passenger_id, count(t1.flight_id) as flight_count from (
    select t.passenger_id, tf.flight_id from tickets t
    join ticket_flights tf on t.ticket_no = tf.ticket_no
  ) t1
  group by t1.passenger_id
) t2;


--8.Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и
-- общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты

with pass_sum_amount as (
  select t1.passenger_id, t1.passenger_name, t1.contact_data, sum(t1.amount) as pass_amount from (
    select t.passenger_id, t.passenger_name, t.contact_data, tf.amount from tickets t
    join ticket_flights tf on t.ticket_no = tf.ticket_no
    join flights f on tf.flight_id = f.flight_id
  ) t1
  group by t1.passenger_id, t1.passenger_name, t1.contact_data
  order by t1.passenger_id, t1.passenger_name, t1.contact_data
)
INSERT INTO bookings.results
select 8 as id, concat_ws('|', passenger_id, passenger_name, contact_data, pass_amount) as response from pass_sum_amount
where pass_amount = (
select min(pass_amount) from pass_sum_amount
);


--9.Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и
-- общее время в полётах, для пассажира, который провёл максимальное время в полётах

with dur_sum_table as (
  select t1.passenger_id, t1.passenger_name, t1.contact_data, sum(t1.actual_duration) as dur_sum from (
    select t.passenger_id, t.passenger_name, t.contact_data, fv.status, fv.actual_duration from tickets t
    join ticket_flights tf on t.ticket_no = tf.ticket_no
    join flights_v fv on tf.flight_id = fv.flight_id
    where fv.actual_duration is not null
  ) t1
  group by t1.passenger_id, t1.passenger_name, t1.contact_data
  order by t1.passenger_id, t1.passenger_name, t1.contact_data
)
INSERT INTO bookings.results
select 9 as id, concat_ws('|', passenger_id, passenger_name, contact_data, dur_sum) as response from dur_sum_table
where dur_sum = (
select max(dur_sum) from dur_sum_table
);


--10.Вывести город(а) с количеством аэропортов больше одного

INSERT INTO bookings.results
select 10 as id, city as response from airports
group by city
having count(airport_code) > 1
order by city;


--11.Вывести город(а), у которого самое меньшее количество городов прямого сообщения

with city_table as (
 select t1.departure_city, count(t1.arrival_city) as arr_city from (
   select distinct departure_city, arrival_city from routes
 ) t1
 group by t1.departure_city
 order by t1.departure_city
)
INSERT INTO bookings.results
select 11 as id, departure_city as response from city_table
where arr_city = (select min(arr_city) from city_table)
order by departure_city;


--12.Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты

with dep_arr_table as (select distinct departure_city, arrival_city from routes)
INSERT INTO bookings.results
select 12 as id, concat_ws('|', t3.departure_city, t3.arrival_city) as response from (
   select t1.departure_city, t2.arrival_city from dep_arr_table t1, dep_arr_table t2
   where t1.departure_city < t2.arrival_city
   except
   select * from dep_arr_table
) t3
order by t3.departure_city, t3.arrival_city;


--13.Вывести города, до которых нельзя добраться без пересадок из Москвы?

INSERT INTO bookings.results
select distinct 13 as id, arrival_city as response from routes
where arrival_city != 'Москва' and arrival_city not in (
        select arrival_city from routes
        where departure_city = 'Москва')
order by arrival_city;


--14.Вывести модель самолета, который выполнил больше всего рейсов

with flight_count as (
   select ad.model, count(f.flight_no) as f_count from flights f 
   join aircrafts ad on f.aircraft_code = ad.aircraft_code 
   where f.status in ('Departed', 'Arrived')
   group by ad.model)
INSERT INTO bookings.results
select 14 as id, model as response from flight_count
where f_count = (select max(f_count) from flight_count);


--15.Вывести модель самолета, который перевез больше всего пассажиров

with pass_count_table as(
   select ad.model, count(t.passenger_id) as pass_count from flights f 
   join aircrafts ad on f.aircraft_code = ad.aircraft_code
   join ticket_flights tf on f.flight_id = tf.flight_id
   join tickets t on tf.ticket_no = t.ticket_no
   where f.status in ('Departed', 'Arrived')
   group by ad.model)
INSERT INTO bookings.results 
select 15 as id, model as response from pass_count_table
	where pass_count = (select max(pass_count) from pass_count_table);


--16.Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам

INSERT INTO bookings.results
select 16 as id, abs(extract(epoch from t1.dif)/60) as response from (
   select (sum(actual_duration) - sum(scheduled_duration)) as dif from flights_v
   where actual_duration is not null
) t1;


--17.Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13

INSERT INTO bookings.results
select distinct 17 as id, arrival_city as response
from flights_v
where departure_city = 'Санкт-Петербург' and cast(actual_departure as date) = '2016-09-13'
order by arrival_city;


--18.Вывести перелёт(ы) с максимальной стоимостью всех билетов

with flight_amount_table as (
   select flight_id, sum(amount) as flight_amount from ticket_flights
   group by flight_id)
INSERT INTO bookings.results
select 18 as id, flight_id as response from flight_amount_table
where flight_amount = (select max(flight_amount) from flight_amount_table);


--19.Выбрать дни в которых было осуществлено минимальное количество перелётов

with flight_count_table as (
   select cast(actual_departure as date) as flight_date, count(flight_id) as flight_count from flights f
   where actual_departure is not null
   group by cast(actual_departure as date)
   order by cast(actual_departure as date))
INSERT INTO bookings.results
select 19 as id, flight_date as response from flight_count_table
where flight_count = (select min(flight_count) from flight_count_table);


--20.Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года

INSERT INTO bookings.results
select 20 as id, case when avg(t1.flight_count) is null then 0 else avg(t1.flight_count) end response from (
   select cast(actual_departure as date) as flight_date, count(flight_id) as flight_count from flights_v
   where departure_city = 'Москва' and actual_departure is not null and date_trunc('month', actual_departure) = '2016-09-01'
   group by cast(actual_departure as date)
) t1;


--21.Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов

INSERT INTO bookings.results
select 21 as id, t2.departure_city as response from (
   select t1.departure_city, avg(t1.dur_hour) as dur_avg from (
      select departure_city, (extract(epoch from actual_duration)/60/60) as dur_hour from flights_v
      where actual_duration is not null
      ) t1
   group by t1.departure_city
   having avg(t1.dur_hour) > 3
) t2
order by t2.dur_avg desc
limit 5;