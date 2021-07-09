--
-- Greenplum Database database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET default_with_oids = false;

--
-- Name: GPDUMPGUC; Type: INTERNAL GUC; Schema: -; Owner: 
--

SET gp_called_by_pgdump = true;


--
-- Name: btc; Type: SCHEMA; Schema: -; Owner: gpadmin
--

CREATE SCHEMA btc;


ALTER SCHEMA btc OWNER TO gpadmin;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: gpadmin
--

COMMENT ON SCHEMA public IS 'Standard public schema';


--
-- Name: ytf; Type: SCHEMA; Schema: -; Owner: gpadmin
--

CREATE SCHEMA ytf;


ALTER SCHEMA ytf OWNER TO gpadmin;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: gpadmin
--

CREATE PROCEDURAL LANGUAGE plpgsql;
ALTER FUNCTION plpgsql_call_handler() OWNER TO gpadmin;
ALTER FUNCTION plpgsql_validator(oid) OWNER TO gpadmin;


SET search_path = public, pg_catalog;

--
-- Name: generate_sql(text); Type: FUNCTION; Schema: public; Owner: oushu
--

CREATE FUNCTION generate_sql(name text) RETURNS text
    AS $_$
   select  'INSERT INTO all_exchange  SELECT  from1, ''' || substring($1, 1, position('_pool' in $1) - 1 ) || '''FROM
  orc_t_ethereum_nm_ta
  WHERE 
  to1 in (
     SELECT 
      address
       FROM
       all_exchange
       WHERE tag_name = ''' || $1 || ''')
  AND 
  from1 not in (
  SELECT
  address
  FROM
  all_exchange
  WHERE
  tag_name like ''%pool%''
 );';
$_$
    LANGUAGE sql CONTAINS SQL;


ALTER FUNCTION public.generate_sql(name text) OWNER TO oushu;

SET search_path = ytf, pg_catalog;

--
-- Name: fun(); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun(OUT out_id integer, OUT out_name text) RETURNS SETOF record
    AS $$
declare
r record;
BEGIN
    for i in 1..5 loop
    select * into r from tb1 where id = i;
    out_id := r.id;
    out_name :=r.name;
    return next;
    end loop;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun(OUT out_id integer, OUT out_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) RETURNS SETOF record
    AS $$
DECLARE 
v_rec RECORD;
BEGIN
for v_rec in 
SELECT 
a.to1,
a.cnt,
b.cnt_tx,
b.sum_value,
b.min_ts,
b.max_ts,
b.is_suspect,
'exchange_name'  
FROM
(
    SELECT
     to1, 
     count(from1) cnt
    FROM
    (
      SELECT
      from1, to1
      FROM
      ytf.orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
       from1
       FROM
       ytf.orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
      GROUP BY from1,to1
    ) c 
    GROUP BY to1 
) a
JOIN
(
    SELECT 
     to1, 
     COUNT(transactionhash)    AS cnt_tx,
     SUM(value::decimal)/10^18 AS sum_value,   
     to_timestamp(MIN(timestamp::bigint))    AS min_ts, 
     to_timestamp(MAX(timestamp::bigint))    AS max_ts, 
     CASE WHEN to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%') THEN 'N' ELSE 'Y' END AS is_suspect
    FROM
    (
      SELECT
      from1, to1, transactionhash, value, timestamp
      FROM
      ytf.orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
        from1
       FROM
       ytf.orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%') 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
    ) c
     GROUP BY to1
) b
ON a.to1 = b.to1
ORDER BY a.cnt DESC
LOOP
 out_address := v_rec.to1;
 out_cnt := v_rec.cnt;
 out_cnt_tx := v_rec.cnt_tx;
 out_sum_value := v_rec.sum_value;
 out_min_ts := v_rec.min_ts;
 out_max_ts := v_rec.max_ts;
 out_is_suspect := v_rec.is_suspect;
 out_exchange_name := exchange_name;
RETURN NEXT;
end loop;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_all(); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_all() RETURNS void
    AS $$
DECLARE 
v_rec text;
BEGIN
/* for v_rec in 
 select tag_name from all_exchange where tag_name not like '%_pool%' GROUP BY tag_name
LOOP
 INSERT INTO suspect_pool_all
 SELECT *
 FROM
 ytf.fun_discover_pool(v_rec);
END LOOP; */
INSERT INTO suspect_pool_all
 SELECT *
 FROM
 ytf.fun_discover_pool('okex');
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_all() OWNER TO oushu;

--
-- Name: fun_discover_pool_all_insert(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_all_insert(tab_name text) RETURNS void
    AS $$
DECLARE 
v_tag_name text;
BEGIN
    execute 'DROP TABLE IF EXISTS ' || tab_name || ';';
    execute 'CREATE TABLE ' || tab_name || '(address text,  cnt int,  cnt_tx int,  sum_value decimal(38,20),  min_ts timestamp,  max_ts timestamp,  is_suspect text, exchange_name text)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);';

for v_tag_name in 
 select tag_name from all_exchange where tag_name not like '%pool%' GROUP BY tag_name
LOOP
 PERFORM *
 FROM
 fun_discover_pool_insert(v_tag_name, tab_name);
END LOOP;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_all_insert(tab_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_all_insert_v2(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_all_insert_v2(tab_name text) RETURNS void
    AS $$
DECLARE 
v_tag_name text;
BEGIN
    execute 'DROP TABLE IF EXISTS ' || tab_name || ';';
    execute 'CREATE TABLE ' || tab_name || '(address text,  cnt int,  cnt_tx int,  sum_value decimal(38,20),  min_ts timestamp,  max_ts timestamp,  is_suspect text, exchange_name text)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);';

for v_tag_name in 
 select tag_name from all_exchange where tag_name not like '%pool%' GROUP BY tag_name
LOOP
 PERFORM *
 FROM
 fun_discover_pool_insert_v2(v_tag_name, tab_name);
END LOOP;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_all_insert_v2(tab_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_insert(text, text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_insert(exchange_name text, tab_name text) RETURNS void
    AS $$
BEGIN
execute 'INSERT INTO ' || tab_name ||
' SELECT 
a.to1,
a.cnt,
b.cnt_tx,
b.sum_value,
b.min_ts,
b.max_ts,
b.is_suspect,'''||
exchange_name ||
''' FROM
(
    SELECT
     to1, 
     count(from1) cnt
    FROM
    (
      SELECT
      from1, to1
      FROM
      ytf.orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
       from1
       FROM
       ytf.orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like '''  || exchange_name || '_pool%'' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like '''|| exchange_name || '_pool%'' )
      ) 
      GROUP BY from1,to1
    ) c 
    GROUP BY to1 
) a
JOIN
(
    SELECT 
     to1, 
     COUNT(transactionhash)    AS cnt_tx,
     SUM(value::decimal)/10^18 AS sum_value,   
     to_timestamp(MIN(timestamp::bigint))    AS min_ts, 
     to_timestamp(MAX(timestamp::bigint))    AS max_ts, 
     CASE WHEN to1 IN (SELECT address FROM all_exchange WHERE tag_name like ''' || exchange_name || '_pool%'') THEN ''N'' ELSE ''Y'' END AS is_suspect
    FROM
    (
      SELECT
      from1, to1, transactionhash, value, timestamp
      FROM
      ytf.orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
        from1
       FROM
       ytf.orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like ''' || exchange_name || '_pool%'') 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like ''' || exchange_name || '_pool%'' )
      ) 
    ) c
     GROUP BY to1
) b
ON a.to1 = b.to1
ORDER BY a.cnt DESC;';
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_insert(exchange_name text, tab_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_insert_v2(text, text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_insert_v2(exchange_name text, tab_name text) RETURNS void
    AS $$
BEGIN
execute 'INSERT INTO ' || tab_name ||
' SELECT 
a.to1,
a.cnt,
b.cnt_tx,
b.sum_value,
b.min_ts,
b.max_ts,
b.is_suspect,'||
exchange_name ||
' FROM
(
    SELECT
     to1, 
     count(from1) cnt
    FROM
    (
      SELECT
      from1, to1
      FROM
      ytf.orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
       from1
       FROM
       ytf.orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like '''  || exchange_name || '_pool%'' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like '''|| exchange_name || '_pool%'' )
      ) 
      AND
      from1 in
      (
          SELECT
          from1
          FROM
          (
              SELECT
              from1,
              to1
              FROM
              orc_t_ethereum_nmta
              WHERE
              from1 in 
              (
               SELECT
               from1
               FROM
               orc_t_ethereum_nmta
               WHERE 
               to1 IN (SELECT address FROM all_exchange WHERE tag_name like '''  || exchange_name || '_pool%'' ) 
               AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like '''|| exchange_name || '_pool%'' )
              ) 
              GROUP BY from1,to1
          ) c 
          GROUP BY from1
          HAVING count(to1) < 200
       )
      GROUP BY from1,to1
    ) e 
    GROUP BY to1 
) a
JOIN
(
    SELECT 
     to1, 
     COUNT(transactionhash)    AS cnt_tx,
     SUM(value::decimal)/10^18 AS sum_value,   
     to_timestamp(MIN(timestamp::bigint))    AS min_ts, 
     to_timestamp(MAX(timestamp::bigint))    AS max_ts, 
     CASE WHEN to1 IN (SELECT address FROM all_exchange WHERE tag_name like ''' || exchange_name || '_pool%'') THEN ''N'' ELSE ''Y'' END AS is_suspect
    FROM
    (
      SELECT
      from1, to1, transactionhash, value, timestamp
      FROM
      ytf.orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
        from1
       FROM
       ytf.orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like ''' || exchange_name || '_pool%'') 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like ''' || exchange_name || '_pool%'' )
      ) 
      AND
      from1 in
      (
         SELECT
          from1
          FROM
          (
              SELECT
              from1,
              to1
              FROM
              orc_t_ethereum_nmta
              WHERE
              from1 in 
              (
               SELECT
               from1
               FROM
               orc_t_ethereum_nmta
               WHERE 
               to1 IN (SELECT address FROM all_exchange WHERE tag_name like '''  || exchange_name || '_pool%'' ) 
               AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like '''|| exchange_name || '_pool%'' )
              ) 
              GROUP BY from1,to1
          ) c 
          GROUP BY from1
          HAVING count(to1) < 200
      )
    ) d
     GROUP BY to1
) b
ON a.to1 = b.to1
ORDER BY a.cnt DESC;';
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_insert_v2(exchange_name text, tab_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_v1(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_v1(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) RETURNS SETOF record
    AS $$
DECLARE 
v_rec RECORD;
BEGIN
for v_rec in 
SELECT 
a.to1,
a.cnt,
b.cnt_tx,
b.sum_value,
b.min_ts,
b.max_ts,
b.is_suspect,
'exchange_name' AS "exchange"
FROM
(
    SELECT
     to1, 
     count(from1) cnt
    FROM
    (
      SELECT
      from1, to1
      FROM
      orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
       from1
       FROM
       orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
      GROUP BY from1,to1
    ) e 
    GROUP BY to1 
) a
JOIN
(
    SELECT 
     to1, 
     COUNT(transactionhash)    AS cnt_tx,
     SUM(value::decimal)/10^18 AS sum_value,   
     to_timestamp(MIN(timestamp::bigint))    AS min_ts, 
     to_timestamp(MAX(timestamp::bigint))    AS max_ts, 
     CASE WHEN to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%') THEN 'N' ELSE 'Y' END AS is_suspect
    FROM
    (
      SELECT
      from1, to1, transactionhash, value, timestamp
      FROM
      orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
        from1
       FROM
       orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%') 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
    ) c
     GROUP BY to1
) b
ON a.to1 = b.to1
ORDER BY a.cnt DESC
LOOP
 out_address := v_rec.to1;
 out_cnt := v_rec.cnt;
 out_cnt_tx := v_rec.cnt_tx;
 out_sum_value := v_rec.sum_value;
 out_min_ts := v_rec.min_ts;
 out_max_ts := v_rec.max_ts;
 out_is_suspect := v_rec.is_suspect;
 out_exchange_name := exchange_name;
RETURN NEXT;
end loop;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_v1(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_v2(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_v2(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) RETURNS SETOF record
    AS $$
DECLARE 
v_rec RECORD;
BEGIN
for v_rec in 
SELECT 
a.to1,
a.cnt,
b.cnt_tx,
b.sum_value,
b.min_ts,
b.max_ts,
b.is_suspect
,'exchange_name' AS "exchange"
FROM
(
    SELECT
     to1, 
     count(from1) cnt
    FROM
    (
      SELECT
      from1, to1
      FROM
      orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
       from1
       FROM
       orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
      AND
      from1 in
      (
          SELECT
          from1
          FROM
          (
              SELECT
              from1,
              to1
              FROM
              orc_t_ethereum_nmta
              WHERE
              from1 in 
              (
               SELECT
               from1
               FROM
               orc_t_ethereum_nmta
               WHERE 
               to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
               AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
              ) 
              GROUP BY from1,to1
          ) c 
          GROUP BY from1
          HAVING count(to1) < 200
      )  
      GROUP BY from1,to1   
    ) e 
    GROUP BY to1 
) a
JOIN
(
    SELECT 
     to1, 
     COUNT(transactionhash)    AS cnt_tx,
     SUM(value::decimal)/10^18 AS sum_value,   
     to_timestamp(MIN(timestamp::bigint))    AS min_ts, 
     to_timestamp(MAX(timestamp::bigint))    AS max_ts, 
     CASE WHEN to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%') THEN 'N' ELSE 'Y' END AS is_suspect
    FROM
    (
      SELECT
      from1, to1, transactionhash, value, timestamp
      FROM
      orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
        from1
       FROM
       orc_t_ethereum_nmta
       WHERE 
        to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
      AND
      from1 in
      (
         SELECT
          from1
          FROM
          (
              SELECT
              from1,
              to1
              FROM
              orc_t_ethereum_nmta
              WHERE
              from1 in 
              (
               SELECT
               from1
               FROM
               orc_t_ethereum_nmta
               WHERE 
               to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
               AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
              ) 
              GROUP BY from1,to1
          ) c 
          GROUP BY from1
          HAVING count(to1) < 200
      )
    ) d
     GROUP BY to1
) b
ON a.to1 = b.to1
ORDER BY a.cnt DESC
LOOP
 out_address := v_rec.to1;
 out_cnt := v_rec.cnt;
 out_cnt_tx := v_rec.cnt_tx;
 out_sum_value := v_rec.sum_value;
 out_min_ts := v_rec.min_ts;
 out_max_ts := v_rec.max_ts;
 out_is_suspect := v_rec.is_suspect;
 out_exchange_name := exchange_name;
RETURN NEXT;
end loop;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_v2(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) OWNER TO oushu;

--
-- Name: fun_discover_pool_v3(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION fun_discover_pool_v3(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) RETURNS SETOF record
    AS $$
DECLARE 
v_rec RECORD;
BEGIN
for v_rec in 
SELECT 
a.to1,
a.cnt,
b.cnt_tx,
b.sum_value,
b.min_ts,
b.max_ts,
b.is_suspect
,'exchange_name' AS "exchange"
FROM
(
    SELECT
     to1, 
     count(from1) cnt
    FROM
    (
      SELECT
      from1, to1
      FROM
      orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
       from1
       FROM
       orc_t_ethereum_nmta
       WHERE 
       to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
      AND
      from1 in
      (
          SELECT
          from1
          FROM
          (
              SELECT
              from1,
              to1
              FROM
              orc_t_ethereum_nmta
              WHERE
              from1 in 
              (
               SELECT
               from1
               FROM
               orc_t_ethereum_nmta
               WHERE 
               to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
               AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
              ) 
              GROUP BY from1,to1
          ) c 
          GROUP BY from1
          HAVING count(to1) < 200
      )  
      GROUP BY from1,to1   
    ) e 
    GROUP BY to1 
) a
JOIN
(
    SELECT 
     to1, 
     COUNT(transactionhash)    AS cnt_tx,
     SUM(value::decimal)/10^18 AS sum_value,   
     to_timestamp(MIN(timestamp::bigint))    AS min_ts, 
     to_timestamp(MAX(timestamp::bigint))    AS max_ts, 
     CASE WHEN to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%') THEN 'N' ELSE 'Y' END AS is_suspect
    FROM
    (
      SELECT
      from1, to1, transactionhash, value, timestamp
      FROM
      orc_t_ethereum_nmta
      WHERE
      from1 in 
      (
       SELECT
        from1
       FROM
       orc_t_ethereum_nmta
       WHERE 
        to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
       AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
      ) 
      AND
      from1 in
      (
         SELECT
          from1
          FROM
          (
              SELECT
              from1,
              to1
              FROM
              orc_t_ethereum_nmta
              WHERE
              from1 in 
              (
               SELECT
               from1
               FROM
               orc_t_ethereum_nmta
               WHERE 
               to1 IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' ) 
               AND from1 NOt IN (SELECT address FROM all_exchange WHERE tag_name like exchange_name || '_pool%' )
              ) 
              GROUP BY from1,to1
          ) c 
          GROUP BY from1
          HAVING count(to1) < 200
      )
    ) d
     GROUP BY to1
) b
ON a.to1 = b.to1
ORDER BY a.cnt DESC
LOOP
 out_address := v_rec.to1;
 out_cnt := v_rec.cnt;
 out_cnt_tx := v_rec.cnt_tx;
 out_sum_value := v_rec.sum_value;
 out_min_ts := v_rec.min_ts;
 out_max_ts := v_rec.max_ts;
 out_is_suspect := v_rec.is_suspect;
 out_exchange_name := exchange_name;
RETURN NEXT;
end loop;
END;
$$
    LANGUAGE plpgsql NO SQL;


ALTER FUNCTION ytf.fun_discover_pool_v3(exchange_name text, OUT out_address text, OUT out_cnt integer, OUT out_cnt_tx integer, OUT out_sum_value numeric, OUT out_min_ts timestamp without time zone, OUT out_max_ts timestamp without time zone, OUT out_is_suspect text, OUT out_exchange_name text) OWNER TO oushu;

--
-- Name: generate_sql(text); Type: FUNCTION; Schema: ytf; Owner: oushu
--

CREATE FUNCTION generate_sql(name text) RETURNS text
    AS $_$
   select  'INSERT INTO all_exchange  SELECT  from1, ''' || substring($1, 1, position('_pool' in $1) - 1 ) || '''FROM
  orc_t_ethereum_nm_ta
  WHERE 
  to1 in (
     SELECT 
      address
       FROM
       all_exchange
       WHERE tag_name = ''' || $1 || ''')
  AND 
  from1 not in (
  SELECT
  address
  FROM
  all_exchange
  WHERE
  tag_name like ''%pool%''
 );';
$_$
    LANGUAGE sql CONTAINS SQL;


ALTER FUNCTION ytf.generate_sql(name text) OWNER TO oushu;

SET search_path = btc, pg_catalog;

SET default_tablespace = '';

--
-- Name: T_JZ_BTC_JY_OUTPOINTS_50; Type: TABLE; Schema: btc; Owner: oushu; Tablespace: 
--

CREATE TABLE "T_JZ_BTC_JY_OUTPOINTS_50" (
    id character varying(400) NOT NULL,
    hash character varying(128),
    block_index double precision,
    o_tx_index_n character varying(200),
    o_tx_index double precision,
    o_tx_n double precision,
    i_tx_index_n character varying(200),
    i_tx_index double precision,
    i_tx_n double precision,
    rksj timestamp without time zone
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE btc."T_JZ_BTC_JY_OUTPOINTS_50" OWNER TO oushu;

--
-- Name: t_jz_btc_jy_inputs; Type: TABLE; Schema: btc; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_btc_jy_inputs (
    id character varying(255) NOT NULL,
    hash character varying(4000),
    inputs_sequence character varying(4000),
    inputs_witness character varying(4000),
    inputs_script character varying(4000),
    inputs_index character varying(4000),
    inputs_prev_spent character varying(4000),
    inputs_prev_script character varying(4000),
    inputs_prev_tx_index character varying(4000),
    inputs_prev_value character varying(4000),
    inputs_prev_addr character varying(4000),
    inputs_prev_n character varying(4000),
    inputs_prev_type character varying(4000),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE btc.t_jz_btc_jy_inputs OWNER TO oushu;

--
-- Name: t_jz_btc_jy_jbxx; Type: TABLE; Schema: btc; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_btc_jy_jbxx (
    id character varying(255) NOT NULL,
    hash character varying(4000),
    ver character varying(4000),
    vin_sz character varying(4000),
    vout_sz character varying(4000),
    jy_size character varying(4000),
    weight character varying(4000),
    fee character varying(4000),
    relayed_by character varying(4000),
    lock_time character varying(4000),
    tx_index character varying(4000),
    double_spend character varying(4000),
    "time" character varying(4000),
    block_index character varying(4000),
    block_height character varying(4000),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE btc.t_jz_btc_jy_jbxx OWNER TO oushu;

--
-- Name: t_jz_btc_jy_out; Type: TABLE; Schema: btc; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_btc_jy_out (
    id character varying(255) NOT NULL,
    hash character varying(4000),
    out_type character varying(4000),
    out_spent character varying(4000),
    out_value character varying(4000),
    spending_outpoints character varying(4000),
    out_n character varying(4000),
    out_tx_index character varying(4000),
    out_script character varying(4000),
    out_addr character varying(4000),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE btc.t_jz_btc_jy_out OWNER TO oushu;

--
-- Name: t_jz_btc_jy_outpoints; Type: TABLE; Schema: btc; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_btc_jy_outpoints (
    id character varying(255) NOT NULL,
    prev_out_script character varying(4000),
    tx_index character varying(4000),
    n character varying(4000),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE btc.t_jz_btc_jy_outpoints OWNER TO oushu;

--
-- Name: t_jz_btc_qk; Type: TABLE; Schema: btc; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_btc_qk (
    id character varying(255) NOT NULL,
    hash character varying(4000),
    ver character varying(4000),
    prev_block character varying(4000),
    mrkl_root character varying(4000),
    "time" character varying(4000),
    bits character varying(4000),
    fee character varying(4000),
    nonce character varying(4000),
    n_tx character varying(4000),
    block_size text,
    block_index character varying(4000),
    main_chain character varying(4000),
    height character varying(4000),
    weight character varying(4000),
    next_block character varying(4000),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE btc.t_jz_btc_qk OWNER TO oushu;

SET search_path = public, pg_catalog;

--
-- Name: account; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account (
    account_name text,
    type integer,
    address text,
    balance bigint,
    net_usage bigint,
    acquired_delegated_frozen_balance_for_bandwidth bigint,
    delegated_frozen_balance_for_bandwidth bigint,
    create_time bigint,
    latest_opration_time bigint,
    allowance bigint,
    latest_withdraw_time bigint,
    code_2l text,
    code_2hs text,
    is_witness boolean,
    is_committee boolean,
    asset_issued_name text,
    asset_issued_id_2l text,
    asset_issued_id_2hs text,
    free_net_usage bigint,
    latest_consume_time bigint,
    latest_consume_free_time bigint,
    account_id text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account OWNER TO oushu;

--
-- Name: account_asset; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_asset (
    account_address text,
    asset_id text,
    amount bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_asset OWNER TO oushu;

--
-- Name: account_asset_v2; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_asset_v2 (
    account_address text,
    asset_id text,
    amount bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_asset_v2 OWNER TO oushu;

--
-- Name: account_create_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE account_create_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    account_address text,
    account_type integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_create_contract OWNER TO gpadmin;

--
-- Name: account_free_asset_net_usage; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_free_asset_net_usage (
    account_address text,
    asset_id text,
    net_usage bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_free_asset_net_usage OWNER TO oushu;

--
-- Name: account_free_asset_net_usage_v2; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_free_asset_net_usage_v2 (
    account_address text,
    asset_id text,
    net_usage bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_free_asset_net_usage_v2 OWNER TO oushu;

--
-- Name: account_frozen; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_frozen (
    account_address text,
    frozen_balance bigint,
    expire_time bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_frozen OWNER TO oushu;

--
-- Name: account_frozen_supply; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_frozen_supply (
    account_address text,
    frozen_balance bigint,
    expire_time bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_frozen_supply OWNER TO oushu;

--
-- Name: account_latest_asset_operation_time; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_latest_asset_operation_time (
    account_address text,
    asset_id text,
    latest_opration_time bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_latest_asset_operation_time OWNER TO oushu;

--
-- Name: account_latest_asset_operation_time_v2; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_latest_asset_operation_time_v2 (
    account_address text,
    asset_id text,
    latest_opration_time bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_latest_asset_operation_time_v2 OWNER TO oushu;

--
-- Name: account_permission_update_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE account_permission_update_contract (
    trans_id text,
    ret integer,
    bytes_hex text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_permission_update_contract OWNER TO gpadmin;

--
-- Name: account_permission_update_contract_actives_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE account_permission_update_contract_actives_v1 (
    trans_id text,
    active_index bigint,
    permission_type integer,
    permission_id integer,
    permission_name text,
    permission_threshold bigint,
    permission_parent_id integer,
    permission_operations text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_permission_update_contract_actives_v1 OWNER TO gpadmin;

--
-- Name: account_permission_update_contract_keys_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE account_permission_update_contract_keys_v1 (
    trans_id text,
    key_sign integer,
    key_index bigint,
    address text,
    address_hex text,
    weight bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_permission_update_contract_keys_v1 OWNER TO gpadmin;

--
-- Name: account_permission_update_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE account_permission_update_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    owner_permission_type integer,
    owner_permission_id integer,
    owner_permission_name text,
    owner_permission_threshold bigint,
    owner_permission_parent_id integer,
    owner_permission_operations text,
    witness_permission_type integer,
    witness_permission_id integer,
    witness_permission_name text,
    witness_permission_threshold bigint,
    witness_permission_parent_id integer,
    witness_permission_operations text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_permission_update_contract_v1 OWNER TO gpadmin;

--
-- Name: account_resource; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_resource (
    account_address text,
    energy_usage bigint,
    frozen_balance_for_energy bigint,
    frozen_balance_for_energy_expire_time bigint,
    latest_consume_time_for_energy bigint,
    acquired_delegated_frozen_balance_for_energy bigint,
    delegated_frozen_balance_for_energy bigint,
    storage_limit bigint,
    storage_usage bigint,
    latest_exchange_storage_time bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_resource OWNER TO oushu;

--
-- Name: account_update_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE account_update_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    account_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_update_contract OWNER TO gpadmin;

--
-- Name: account_votes; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE account_votes (
    account_address text,
    vote_address text,
    vote_count bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.account_votes OWNER TO oushu;

--
-- Name: ana_wuhao; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ana_wuhao (
    cion_type text,
    to_addrees text,
    amount double precision,
    txid text,
    create_time text,
    upate_time text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ana_wuhao OWNER TO oushu;

--
-- Name: asset_issue_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE asset_issue_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    id text,
    owner_address text,
    name_ text,
    abbr text,
    total_supply bigint,
    trx_num integer,
    "precision" integer,
    num integer,
    start_time bigint,
    end_time bigint,
    order_ bigint,
    vote_score integer,
    description text,
    url text,
    free_asset_net_limit bigint,
    public_free_asset_net_limit bigint,
    public_free_asset_net_usage bigint,
    public_latest_free_net_time bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.asset_issue_contract OWNER TO gpadmin;

--
-- Name: asset_issue_contract_frozen_supply; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE asset_issue_contract_frozen_supply (
    trans_id text,
    frozen_amount bigint,
    frozen_days bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.asset_issue_contract_frozen_supply OWNER TO gpadmin;

--
-- Name: asset_issue_v2; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE asset_issue_v2 (
    id text,
    name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.asset_issue_v2 OWNER TO gpadmin;

--
-- Name: asset_issue_v2_frozen_supply; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE asset_issue_v2_frozen_supply (
    asset_id text,
    asset_name text,
    frozen_amount bigint,
    frozen_days bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.asset_issue_v2_frozen_supply OWNER TO gpadmin;

--
-- Name: block; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE block (
    block_num bigint,
    hash text,
    parent_hash text,
    create_time bigint,
    version integer,
    witness_address text,
    witness_id bigint,
    tx_count integer,
    tx_trie_root text,
    witness_signature text,
    account_state_root text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.block OWNER TO gpadmin;

--
-- Name: clear_abi_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE clear_abi_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.clear_abi_contract OWNER TO gpadmin;

--
-- Name: create_smart_contract; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE create_smart_contract (
    trans_id text,
    ret integer,
    bytes_hex text
)FORMAT 'csv';


ALTER EXTERNAL TABLE public.create_smart_contract OWNER TO oushu;

--
-- Name: create_smart_contract_abi_inputs_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE create_smart_contract_abi_inputs_v1 (
    trans_id text,
    entry_id integer,
    indexed boolean,
    name text,
    type text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.create_smart_contract_abi_inputs_v1 OWNER TO gpadmin;

--
-- Name: create_smart_contract_abi_outputs_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE create_smart_contract_abi_outputs_v1 (
    trans_id text,
    entry_id integer,
    indexed boolean,
    name text,
    type text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.create_smart_contract_abi_outputs_v1 OWNER TO gpadmin;

--
-- Name: create_smart_contract_abi_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE create_smart_contract_abi_v1 (
    trans_id text,
    tmp_ret integer,
    tmp_provider text,
    tmp_name text,
    tmp_permission_id integer,
    anonymous boolean,
    constant boolean,
    name text,
    type integer,
    payable boolean,
    state_mutability integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.create_smart_contract_abi_v1 OWNER TO gpadmin;

--
-- Name: create_smart_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE create_smart_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    call_token_value bigint,
    token_id bigint,
    origin_address text,
    contract_address text,
    bytecode text,
    call_value bigint,
    consume_user_resource_percent bigint,
    name_contract text,
    origin_energy_limit bigint,
    code_hash text,
    trx_hash text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.create_smart_contract_v1 OWNER TO gpadmin;

--
-- Name: deposit; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE deposit (
    cion_type text,
    to_addrees text,
    amount double precision,
    txid text,
    create_time text,
    upate_time text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.deposit OWNER TO oushu;

--
-- Name: deposit_txids; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE deposit_txids (
    txid text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.deposit_txids OWNER TO oushu;

--
-- Name: deposit_withdraw_record; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE deposit_withdraw_record (
    address text,
    ordernum text,
    uid text,
    way text,
    coin text,
    "time" date,
    value text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.deposit_withdraw_record OWNER TO oushu;

--
-- Name: err_trans_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE err_trans_v1 (
    block_num bigint,
    trans_id text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.err_trans_v1 OWNER TO gpadmin;

--
-- Name: error_account; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE error_account (
    account_index bigint,
    account_hex text,
    account_address text
)FORMAT 'csv';


ALTER EXTERNAL TABLE public.error_account OWNER TO oushu;

--
-- Name: error_asset_id; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE error_asset_id (
    asset_id bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.error_asset_id OWNER TO gpadmin;

--
-- Name: error_block_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE error_block_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.error_block_errs OWNER TO gpadmin;

--
-- Name: error_block_num; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE error_block_num (
    block_num bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.error_block_num OWNER TO gpadmin;

--
-- Name: errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.errs OWNER TO gpadmin;

--
-- Name: exchange_create_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE exchange_create_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    first_token_id text,
    first_token_balance bigint,
    second_token_id text,
    second_token_balance bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.exchange_create_contract OWNER TO gpadmin;

--
-- Name: exchange_inject_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE exchange_inject_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.exchange_inject_contract OWNER TO gpadmin;

--
-- Name: exchange_transaction_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE exchange_transaction_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint,
    expected bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.exchange_transaction_contract OWNER TO gpadmin;

--
-- Name: exchange_withdraw_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE exchange_withdraw_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.exchange_withdraw_contract OWNER TO gpadmin;

--
-- Name: ext_account_create_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_account_create_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_account_create_contract_errs OWNER TO gpadmin;

--
-- Name: ext_account_create_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_account_create_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    account_address text,
    account_type integer
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/account_create_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/account_create_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/account_create_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/account_create_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/account_create_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/account_create_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/account_create_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/account_create_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/account_create_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/account_create_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/account_create_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/account_create_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_account_create_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_account_create_contract OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_account_permission_update_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_account_permission_update_contract_errs OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_account_permission_update_contract (
    trans_id text,
    ret integer,
    bytes_hex text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/account_permission_update_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/account_permission_update_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/account_permission_update_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/account_permission_update_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/account_permission_update_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/account_permission_update_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/account_permission_update_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/account_permission_update_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/account_permission_update_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/account_permission_update_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/account_permission_update_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/account_permission_update_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_account_permission_update_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_account_permission_update_contract OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_actives_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_account_permission_update_contract_actives_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_account_permission_update_contract_actives_v1_errs OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_actives_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_account_permission_update_contract_actives_v1 (
    trans_id text,
    active_index bigint,
    permission_type integer,
    permission_id integer,
    permission_name text,
    permission_threshold bigint,
    permission_parent_id integer,
    permission_operations text
) LOCATION (
    'gpfdist://tron1:8082/account_permission_update_contract_actives_v1/0-5000000.csv',
    'gpfdist://tron2:8082/account_permission_update_contract_actives_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/account_permission_update_contract_actives_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/account_permission_update_contract_actives_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/account_permission_update_contract_actives_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/account_permission_update_contract_actives_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_account_permission_update_contract_actives_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_account_permission_update_contract_actives_v1 OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_keys_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_account_permission_update_contract_keys_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_account_permission_update_contract_keys_v1_errs OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_keys_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_account_permission_update_contract_keys_v1 (
    trans_id text,
    key_sign integer,
    key_index bigint,
    address text,
    address_hex text,
    weight bigint
) LOCATION (
    'gpfdist://tron1:8082/account_permission_update_contract_keys_v1/0-5000000.csv',
    'gpfdist://tron2:8082/account_permission_update_contract_keys_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/account_permission_update_contract_keys_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/account_permission_update_contract_keys_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/account_permission_update_contract_keys_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/account_permission_update_contract_keys_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_account_permission_update_contract_keys_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_account_permission_update_contract_keys_v1 OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_account_permission_update_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_account_permission_update_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_account_permission_update_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_account_permission_update_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    owner_permission_type integer,
    owner_permission_id integer,
    owner_permission_name text,
    owner_permission_threshold bigint,
    owner_permission_parent_id integer,
    owner_permission_operations text,
    witness_permission_type integer,
    witness_permission_id integer,
    witness_permission_name text,
    witness_permission_threshold bigint,
    witness_permission_parent_id integer,
    witness_permission_operations text
) LOCATION (
    'gpfdist://tron1:8082/account_permission_update_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/account_permission_update_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/account_permission_update_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/account_permission_update_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/account_permission_update_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/account_permission_update_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_account_permission_update_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_account_permission_update_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_account_update_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_account_update_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_account_update_contract_errs OWNER TO gpadmin;

--
-- Name: ext_account_update_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_account_update_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    account_name text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/account_update_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/account_update_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/account_update_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/account_update_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/account_update_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/account_update_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/account_update_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/account_update_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/account_update_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/account_update_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/account_update_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/account_update_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_account_update_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_account_update_contract OWNER TO gpadmin;

--
-- Name: ext_asset_issue_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_asset_issue_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_asset_issue_contract_errs OWNER TO gpadmin;

--
-- Name: ext_asset_issue_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_asset_issue_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    id text,
    owner_address text,
    name_ text,
    abbr text,
    total_supply bigint,
    trx_num integer,
    "precision" integer,
    num integer,
    start_time bigint,
    end_time bigint,
    order_ bigint,
    vote_score integer,
    description text,
    url text,
    free_asset_net_limit bigint,
    public_free_asset_net_limit bigint,
    public_free_asset_net_usage bigint,
    public_latest_free_net_time bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/asset_issue_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/asset_issue_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/asset_issue_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/asset_issue_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/asset_issue_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/asset_issue_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/asset_issue_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/asset_issue_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/asset_issue_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/asset_issue_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/asset_issue_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/asset_issue_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_asset_issue_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_asset_issue_contract OWNER TO gpadmin;

--
-- Name: ext_asset_issue_contract_frozen_supply_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_asset_issue_contract_frozen_supply_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_asset_issue_contract_frozen_supply_errs OWNER TO gpadmin;

--
-- Name: ext_asset_issue_contract_frozen_supply; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_asset_issue_contract_frozen_supply (
    trans_id text,
    frozen_amount bigint,
    frozen_days bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/asset_issue_contract_frozen_supply/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/asset_issue_contract_frozen_supply/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/asset_issue_contract_frozen_supply/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/asset_issue_contract_frozen_supply/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/asset_issue_contract_frozen_supply/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/asset_issue_contract_frozen_supply/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/asset_issue_contract_frozen_supply/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/asset_issue_contract_frozen_supply/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/asset_issue_contract_frozen_supply/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/asset_issue_contract_frozen_supply/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/asset_issue_contract_frozen_supply/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/asset_issue_contract_frozen_supply/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_asset_issue_contract_frozen_supply_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_asset_issue_contract_frozen_supply OWNER TO gpadmin;

--
-- Name: ext_block_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_block_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_block_errs OWNER TO gpadmin;

--
-- Name: ext_block; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_block (
    block_num bigint,
    hash text,
    parent_hash text,
    create_time bigint,
    version integer,
    witness_address text,
    witness_id bigint,
    tx_count integer,
    tx_trie_root text,
    witness_signature text,
    account_state_root text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/block/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/block/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/block/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/block/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/block/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/block/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/block/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/block/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/block/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/block/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/block/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/block/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_block_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_block OWNER TO gpadmin;

--
-- Name: ext_clear_abi_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_clear_abi_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_clear_abi_contract_errs OWNER TO gpadmin;

--
-- Name: ext_clear_abi_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_clear_abi_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/clear_abi_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/clear_abi_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/clear_abi_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/clear_abi_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/clear_abi_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/clear_abi_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/clear_abi_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/clear_abi_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/clear_abi_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/clear_abi_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/clear_abi_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/clear_abi_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_clear_abi_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_clear_abi_contract OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_create_smart_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_create_smart_contract_errs OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_create_smart_contract (
    trans_id text,
    ret integer,
    bytes_hex text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/create_smart_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/create_smart_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/create_smart_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/create_smart_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/create_smart_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/create_smart_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/create_smart_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/create_smart_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/create_smart_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/create_smart_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/create_smart_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/create_smart_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_create_smart_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_create_smart_contract OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_abi_inputs_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_create_smart_contract_abi_inputs_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_create_smart_contract_abi_inputs_v1_errs OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_abi_inputs_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_create_smart_contract_abi_inputs_v1 (
    trans_id text,
    entry_id integer,
    indexed boolean,
    name text,
    type text
) LOCATION (
    'gpfdist://tron1:8082/create_smart_contract_abi_inputs_v1/0-5000000.csv',
    'gpfdist://tron2:8082/create_smart_contract_abi_inputs_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/create_smart_contract_abi_inputs_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/create_smart_contract_abi_inputs_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/create_smart_contract_abi_inputs_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/create_smart_contract_abi_inputs_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_create_smart_contract_abi_inputs_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_create_smart_contract_abi_inputs_v1 OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_abi_outputs_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_create_smart_contract_abi_outputs_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_create_smart_contract_abi_outputs_v1_errs OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_abi_outputs_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_create_smart_contract_abi_outputs_v1 (
    trans_id text,
    entry_id integer,
    indexed boolean,
    name text,
    type text
) LOCATION (
    'gpfdist://tron1:8082/create_smart_contract_abi_outputs_v1/0-5000000.csv',
    'gpfdist://tron2:8082/create_smart_contract_abi_outputs_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/create_smart_contract_abi_outputs_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/create_smart_contract_abi_outputs_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/create_smart_contract_abi_outputs_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/create_smart_contract_abi_outputs_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_create_smart_contract_abi_outputs_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_create_smart_contract_abi_outputs_v1 OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_abi_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_create_smart_contract_abi_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_create_smart_contract_abi_v1_errs OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_abi_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_create_smart_contract_abi_v1 (
    trans_id text,
    tmp_ret integer,
    tmp_provider text,
    tmp_name text,
    tmp_permission_id integer,
    anonymous boolean,
    constant boolean,
    name text,
    type integer,
    payable boolean,
    state_mutability integer
) LOCATION (
    'gpfdist://tron1:8082/create_smart_contract_abi_v1/0-5000000.csv',
    'gpfdist://tron2:8082/create_smart_contract_abi_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/create_smart_contract_abi_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/create_smart_contract_abi_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/create_smart_contract_abi_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/create_smart_contract_abi_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_create_smart_contract_abi_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_create_smart_contract_abi_v1 OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_create_smart_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_create_smart_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_create_smart_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_create_smart_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    call_token_value bigint,
    token_id bigint,
    origin_address text,
    contract_address text,
    bytecode text,
    call_value bigint,
    consume_user_resource_percent bigint,
    name_contract text,
    origin_energy_limit bigint,
    code_hash text,
    trx_hash text
) LOCATION (
    'gpfdist://tron1:8082/create_smart_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/create_smart_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/create_smart_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/create_smart_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/create_smart_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/create_smart_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_create_smart_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_create_smart_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_err_trans_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_err_trans_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_err_trans_v1_errs OWNER TO gpadmin;

--
-- Name: ext_err_trans_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_err_trans_v1 (
    block_num bigint,
    trans_id text
) LOCATION (
    'gpfdist://tron1:8082/err_trans_v1/0-5000000.csv',
    'gpfdist://tron2:8082/err_trans_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/err_trans_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/err_trans_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/err_trans_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/err_trans_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_err_trans_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_err_trans_v1 OWNER TO gpadmin;

--
-- Name: ext_error_block_num; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_error_block_num (
    block_num bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/error_block_num/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/error_block_num/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/error_block_num/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/error_block_num/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/error_block_num/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/error_block_num/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/error_block_num/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/error_block_num/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/error_block_num/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/error_block_num/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/error_block_num/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/error_block_num/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.error_block_errs SEGMENT REJECT LIMIT 5 ROWS;


ALTER EXTERNAL TABLE public.ext_error_block_num OWNER TO gpadmin;

--
-- Name: ext_exchange_create_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_exchange_create_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_exchange_create_contract_errs OWNER TO gpadmin;

--
-- Name: ext_exchange_create_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_exchange_create_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    first_token_id text,
    first_token_balance bigint,
    second_token_id text,
    second_token_balance bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/exchange_create_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/exchange_create_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/exchange_create_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_create_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_create_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_create_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_create_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_create_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_create_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_create_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_create_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_create_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_exchange_create_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_exchange_create_contract OWNER TO gpadmin;

--
-- Name: ext_exchange_inject_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_exchange_inject_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_exchange_inject_contract_errs OWNER TO gpadmin;

--
-- Name: ext_exchange_inject_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_exchange_inject_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/exchange_inject_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/exchange_inject_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/exchange_inject_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_inject_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_inject_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_inject_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_inject_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_inject_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_inject_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_inject_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_inject_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_inject_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_exchange_inject_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_exchange_inject_contract OWNER TO gpadmin;

--
-- Name: ext_exchange_transaction_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_exchange_transaction_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_exchange_transaction_contract_errs OWNER TO gpadmin;

--
-- Name: ext_exchange_transaction_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_exchange_transaction_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint,
    expected bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/exchange_transaction_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/exchange_transaction_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/exchange_transaction_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_transaction_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_transaction_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_transaction_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_transaction_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_transaction_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_transaction_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_transaction_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_transaction_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_transaction_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_exchange_transaction_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_exchange_transaction_contract OWNER TO gpadmin;

--
-- Name: ext_exchange_withdraw_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_exchange_withdraw_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_exchange_withdraw_contract_errs OWNER TO gpadmin;

--
-- Name: ext_exchange_withdraw_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_exchange_withdraw_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/exchange_withdraw_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/exchange_withdraw_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/exchange_withdraw_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_withdraw_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_withdraw_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_withdraw_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_withdraw_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_withdraw_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_withdraw_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_withdraw_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_withdraw_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_withdraw_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_exchange_withdraw_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_exchange_withdraw_contract OWNER TO gpadmin;

--
-- Name: ext_freeze_balance_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_freeze_balance_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_freeze_balance_contract_errs OWNER TO gpadmin;

--
-- Name: ext_freeze_balance_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_freeze_balance_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    frozen_balance bigint,
    frozen_duration bigint,
    resource integer,
    receiver_address text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/freeze_balance_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/freeze_balance_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/freeze_balance_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/freeze_balance_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/freeze_balance_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/freeze_balance_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/freeze_balance_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/freeze_balance_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/freeze_balance_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/freeze_balance_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/freeze_balance_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/freeze_balance_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_freeze_balance_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_freeze_balance_contract OWNER TO gpadmin;

--
-- Name: ext_market_cancel_order_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_market_cancel_order_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_market_cancel_order_contract_errs OWNER TO gpadmin;

--
-- Name: ext_market_cancel_order_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_market_cancel_order_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    order_id text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/market_cancel_order_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/market_cancel_order_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/market_cancel_order_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/market_cancel_order_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/market_cancel_order_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/market_cancel_order_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/market_cancel_order_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/market_cancel_order_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/market_cancel_order_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/market_cancel_order_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/market_cancel_order_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/market_cancel_order_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_market_cancel_order_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_market_cancel_order_contract OWNER TO gpadmin;

--
-- Name: ext_market_cancel_order_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_market_cancel_order_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_market_cancel_order_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_market_cancel_order_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_market_cancel_order_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    order_id text
) LOCATION (
    'gpfdist://tron1:8082/market_cancel_order_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/market_cancel_order_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/market_cancel_order_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/market_cancel_order_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/market_cancel_order_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/market_cancel_order_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_market_cancel_order_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_market_cancel_order_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_market_sell_asset_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_market_sell_asset_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_market_sell_asset_contract_errs OWNER TO gpadmin;

--
-- Name: ext_market_sell_asset_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_market_sell_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    sell_token_id text,
    sell_token_quantity bigint,
    buy_token_id text,
    buy_token_quantity bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/market_sell_asset_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/market_sell_asset_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/market_sell_asset_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/market_sell_asset_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/market_sell_asset_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/market_sell_asset_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/market_sell_asset_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/market_sell_asset_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/market_sell_asset_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/market_sell_asset_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/market_sell_asset_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/market_sell_asset_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_market_sell_asset_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_market_sell_asset_contract OWNER TO gpadmin;

--
-- Name: ext_market_sell_asset_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_market_sell_asset_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_market_sell_asset_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_market_sell_asset_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_market_sell_asset_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    sell_token_id text,
    sell_token_quantity bigint,
    buy_token_id text,
    buy_token_quantity bigint
) LOCATION (
    'gpfdist://tron1:8082/market_sell_asset_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/market_sell_asset_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/market_sell_asset_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/market_sell_asset_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/market_sell_asset_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/market_sell_asset_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_market_sell_asset_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_market_sell_asset_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_participate_asset_issue_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_participate_asset_issue_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_participate_asset_issue_contract_errs OWNER TO gpadmin;

--
-- Name: ext_participate_asset_issue_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_participate_asset_issue_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    to_address text,
    asset_name text,
    amount bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/participate_asset_issue_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/participate_asset_issue_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/participate_asset_issue_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/participate_asset_issue_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/participate_asset_issue_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/participate_asset_issue_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/participate_asset_issue_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/participate_asset_issue_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/participate_asset_issue_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/participate_asset_issue_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/participate_asset_issue_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/participate_asset_issue_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_participate_asset_issue_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_participate_asset_issue_contract OWNER TO gpadmin;

--
-- Name: ext_proposal_approve_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_proposal_approve_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_proposal_approve_contract_errs OWNER TO gpadmin;

--
-- Name: ext_proposal_approve_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_proposal_approve_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    proposal_id bigint,
    is_add_approval boolean
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/proposal_approve_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/proposal_approve_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/proposal_approve_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/proposal_approve_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/proposal_approve_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/proposal_approve_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/proposal_approve_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/proposal_approve_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/proposal_approve_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/proposal_approve_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/proposal_approve_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/proposal_approve_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_proposal_approve_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_proposal_approve_contract OWNER TO gpadmin;

--
-- Name: ext_proposal_create_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_proposal_create_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_proposal_create_contract_errs OWNER TO gpadmin;

--
-- Name: ext_proposal_create_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_proposal_create_contract (
    trans_id text,
    ret integer,
    bytes_hex text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/proposal_create_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/proposal_create_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/proposal_create_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/proposal_create_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/proposal_create_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/proposal_create_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/proposal_create_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/proposal_create_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/proposal_create_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/proposal_create_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/proposal_create_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/proposal_create_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_proposal_create_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_proposal_create_contract OWNER TO gpadmin;

--
-- Name: ext_proposal_create_contract_parameters_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_proposal_create_contract_parameters_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_proposal_create_contract_parameters_v1_errs OWNER TO gpadmin;

--
-- Name: ext_proposal_create_contract_parameters_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_proposal_create_contract_parameters_v1 (
    p_key bigint,
    p_value bigint
) LOCATION (
    'gpfdist://tron1:8082/proposal_create_contract_parameters_v1/0-5000000.csv',
    'gpfdist://tron2:8082/proposal_create_contract_parameters_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/proposal_create_contract_parameters_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/proposal_create_contract_parameters_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/proposal_create_contract_parameters_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/proposal_create_contract_parameters_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_proposal_create_contract_parameters_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_proposal_create_contract_parameters_v1 OWNER TO gpadmin;

--
-- Name: ext_proposal_create_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_proposal_create_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_proposal_create_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_proposal_create_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_proposal_create_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text
) LOCATION (
    'gpfdist://tron1:8082/proposal_create_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/proposal_create_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/proposal_create_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/proposal_create_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/proposal_create_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/proposal_create_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_proposal_create_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_proposal_create_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_proposal_delete_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_proposal_delete_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_proposal_delete_contract_errs OWNER TO gpadmin;

--
-- Name: ext_proposal_delete_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_proposal_delete_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    proposal_id bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/proposal_delete_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/proposal_delete_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/proposal_delete_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/proposal_delete_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/proposal_delete_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/proposal_delete_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/proposal_delete_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/proposal_delete_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/proposal_delete_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/proposal_delete_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/proposal_delete_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/proposal_delete_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_proposal_delete_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_proposal_delete_contract OWNER TO gpadmin;

--
-- Name: ext_set_account_id_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_set_account_id_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_set_account_id_contract_errs OWNER TO gpadmin;

--
-- Name: ext_set_account_id_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_set_account_id_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    account_id text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/set_account_id_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/set_account_id_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/set_account_id_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/set_account_id_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/set_account_id_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/set_account_id_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/set_account_id_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/set_account_id_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/set_account_id_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/set_account_id_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/set_account_id_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/set_account_id_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_set_account_id_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_set_account_id_contract OWNER TO gpadmin;

--
-- Name: ext_shielded_transfer_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_shielded_transfer_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_shielded_transfer_contract_errs OWNER TO gpadmin;

--
-- Name: ext_shielded_transfer_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_shielded_transfer_contract (
    trans_id text,
    ret integer,
    bytes_hex text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/shielded_transfer_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/shielded_transfer_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/shielded_transfer_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/shielded_transfer_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/shielded_transfer_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/shielded_transfer_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/shielded_transfer_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/shielded_transfer_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/shielded_transfer_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/shielded_transfer_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/shielded_transfer_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/shielded_transfer_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_shielded_transfer_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_shielded_transfer_contract OWNER TO gpadmin;

--
-- Name: ext_shielded_transfer_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_shielded_transfer_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_shielded_transfer_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_shielded_transfer_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_shielded_transfer_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    transparent_from_address text,
    from_amount bigint,
    binding_signature text,
    transparent_to_address text,
    to_amount bigint,
    spend_description_value_commitment text,
    spend_description_anchor text,
    spend_description_nullifier text,
    spend_description_rk text,
    spend_description_zkproof text,
    spend_description_spend_authority_signature text,
    receive_description_value_commitment text,
    receive_description_note_commitment text,
    receive_description_epk text,
    receive_description_c_enc text,
    receive_description_c_out text,
    receive_description_zkproof text
) LOCATION (
    'gpfdist://tron1:8082/shielded_transfer_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/shielded_transfer_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/shielded_transfer_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/shielded_transfer_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/shielded_transfer_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/shielded_transfer_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_shielded_transfer_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_shielded_transfer_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_erc20_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_t_ethereum_erc20_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_t_ethereum_erc20_errs OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_erc20; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_t_ethereum_erc20 (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text
) LOCATION (
    'gpfdist://tron1:8081/ERCT20/0to999999_ERC20Transaction.csv',
    'gpfdist://tron1:8081/ERCT20/1000000to1999999_ERC20Transaction.csv',
    'gpfdist://tron2:8081/ERCT20/2000000to2999999_ERC20Transaction.csv',
    'gpfdist://tron2:8081/ERCT20/3000000to3999999_ERC20Transaction.csv',
    'gpfdist://tron3:8081/ERCT20/4000000to4999999_ERC20Transaction.csv',
    'gpfdist://tron3:8081/ERCT20/5000000to5999999_ERC20Transaction.csv',
    'gpfdist://tron4:8081/ERCT20/6000000to6999999_ERC20Transaction.csv',
    'gpfdist://tron4:8081/ERCT20/7000000to7999999_ERC20Transaction.csv',
    'gpfdist://tron5:8081/ERCT20/8000000to8999999_ERC20Transaction.csv',
    'gpfdist://tron5:8081/ERCT20/9000000to9999999_ERC20Transaction.csv',
    'gpfdist://tron6:8081/ERCT20/10000000to10999999_ERC20Transaction.csv',
    'gpfdist://tron6:8081/ERCT20/11000000to11999999_ERC20Transaction.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_t_ethereum_erc20_errs SEGMENT REJECT LIMIT 50000 ROWS;


ALTER EXTERNAL TABLE public.ext_t_ethereum_erc20 OWNER TO gpadmin;

--
-- Name: ext_trans_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_errs OWNER TO gpadmin;

--
-- Name: ext_trans; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/trans/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/trans/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trans/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trans/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trans/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trans/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans OWNER TO gpadmin;

--
-- Name: ext_trans0_250_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans0_250_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans0_250_errs OWNER TO oushu;

--
-- Name: ext_trans0_250; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans0_250 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans/0-2500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans0_250_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans0_250 OWNER TO oushu;

--
-- Name: ext_trans1_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans1_errs OWNER TO oushu;

--
-- Name: ext_trans1; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans1 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron2:8081/block_parsed_500_750w/trans/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trans/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trans/10000000-12500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans1_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans1 OWNER TO oushu;

--
-- Name: ext_trans1250_2000_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans1250_2000_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans1250_2000_errs OWNER TO oushu;

--
-- Name: ext_trans1250_2000; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans1250_2000 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans/17500000-20000000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans1250_2000_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans1250_2000 OWNER TO oushu;

--
-- Name: ext_trans2_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans2_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans2_errs OWNER TO oushu;

--
-- Name: ext_trans2; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans2 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans/0-2500000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans/15000000-17500000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trans/25000000-27500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans2_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans2 OWNER TO oushu;

--
-- Name: ext_trans2000_last_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans2000_last_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans2000_last_errs OWNER TO oushu;

--
-- Name: ext_trans2000_last; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans2000_last (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trans/20000000-22500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans2000_last_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans2000_last OWNER TO oushu;

--
-- Name: ext_trans250_500_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans250_500_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans250_500_errs OWNER TO oushu;

--
-- Name: ext_trans250_500; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans250_500 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_250_500w/trans/2500000-5000000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans250_500_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans250_500 OWNER TO oushu;

--
-- Name: ext_trans2_1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans2_1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans2_1_errs OWNER TO gpadmin;

--
-- Name: ext_trans2_1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans2_1 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans/0-2500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans2_1_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans2_1 OWNER TO gpadmin;

--
-- Name: ext_trans2_2_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans2_2_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans2_2_errs OWNER TO gpadmin;

--
-- Name: ext_trans2_2; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans2_2 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans/15000000-17500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans2_2_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans2_2 OWNER TO gpadmin;

--
-- Name: ext_trans2_3_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans2_3_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans2_3_errs OWNER TO gpadmin;

--
-- Name: ext_trans2_3; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans2_3 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trans/25000000-27500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans2_3_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans2_3 OWNER TO gpadmin;

--
-- Name: ext_trans3_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans3_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans3_errs OWNER TO gpadmin;

--
-- Name: ext_trans3; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans3 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans/12500000-15000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trans/20000000-22500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans3_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans3 OWNER TO gpadmin;

--
-- Name: ext_trans4_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans4_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans4_errs OWNER TO gpadmin;

--
-- Name: ext_trans4; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans4 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans4_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans4 OWNER TO gpadmin;

--
-- Name: ext_trans4_1_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans4_1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans4_1_errs OWNER TO oushu;

--
-- Name: ext_trans4_1; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans4_1 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans/12500000-15000000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans4_1_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans4_1 OWNER TO oushu;

--
-- Name: ext_trans4_2_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans4_2_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans4_2_errs OWNER TO oushu;

--
-- Name: ext_trans4_2; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans4_2 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans/22500000-25000000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans4_2_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans4_2 OWNER TO oushu;

--
-- Name: ext_trans4_2_1_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans4_2_1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans4_2_1_errs OWNER TO oushu;

--
-- Name: ext_trans4_2_1; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans4_2_1 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans/17500000-20000000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans4_2_1_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans4_2_1 OWNER TO oushu;

--
-- Name: ext_trans4_2_2_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans4_2_2_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans4_2_2_errs OWNER TO oushu;

--
-- Name: ext_trans4_2_2; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans4_2_2 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans/22500000-25000000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans4_2_2_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans4_2_2 OWNER TO oushu;

--
-- Name: ext_trans500_1250_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans500_1250_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans500_1250_errs OWNER TO oushu;

--
-- Name: ext_trans500_1250; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans500_1250 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron2:8081/block_parsed_500_750w/trans/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trans/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trans/10000000-12500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans500_1250_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans500_1250 OWNER TO oushu;

--
-- Name: ext_trans_auths_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans_auths_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_auths_errs OWNER TO gpadmin;

--
-- Name: ext_trans_auths; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_auths (
    trans_id text,
    account_address text,
    account_name text,
    permission_name text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans_auths/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/trans_auths/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/trans_auths/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trans_auths/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trans_auths/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans_auths/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans_auths/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans_auths/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trans_auths/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans_auths/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trans_auths/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans_auths/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_auths_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_auths OWNER TO gpadmin;

--
-- Name: ext_trans_market_order_detail_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans_market_order_detail_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_market_order_detail_errs OWNER TO gpadmin;

--
-- Name: ext_trans_market_order_detail; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_market_order_detail (
    trans_id text,
    makerorderid text,
    taker_order_id text,
    fill_sell_quantity bigint,
    fill_buy_quantity bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans_market_order_detail/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/trans_market_order_detail/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/trans_market_order_detail/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trans_market_order_detail/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trans_market_order_detail/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans_market_order_detail/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans_market_order_detail/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans_market_order_detail/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trans_market_order_detail/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans_market_order_detail/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trans_market_order_detail/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans_market_order_detail/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_market_order_detail_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_market_order_detail OWNER TO gpadmin;

--
-- Name: ext_trans_ret_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_errs OWNER TO oushu;

--
-- Name: ext_trans_ret; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret (
    id text,
    fee bigint,
    block_number bigint,
    block_timestamp bigint,
    contract_address text,
    receipt_energy_usage bigint,
    receipt_energy_fee bigint,
    receipt_origin_energy_usage bigint,
    receipt_energy_usage_total bigint,
    receipt_net_usage bigint,
    receipt_net_fee bigint,
    receipt_result integer,
    result integer,
    resmessage text,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    packing_fee bigint
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret OWNER TO oushu;

--
-- Name: ext_trans_ret_contract_result_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_contract_result_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_contract_result_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_contract_result; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_contract_result (
    trans_id text,
    result_index integer,
    result text
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_contract_result/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_contract_result/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_contract_result/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_contract_result/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_contract_result/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_contract_result/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_contract_result/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_contract_result/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_contract_result/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_contract_result/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_contract_result/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_contract_result/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_contract_result_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_contract_result OWNER TO oushu;

--
-- Name: ext_trans_ret_error_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_error_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_error_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_error; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_error (
    type text,
    id text,
    err text
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_error/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_error/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_error/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_error/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_error/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_error/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_error/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_error/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_error/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_error/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_error/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_error/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_error_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_error OWNER TO oushu;

--
-- Name: ext_trans_ret_inter_trans_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_inter_trans_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_inter_trans_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_inter_trans; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_inter_trans (
    trans_id text,
    inter_index integer,
    hash text,
    caller_address text,
    transferto_address text,
    note text,
    rejected boolean
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_inter_trans/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_inter_trans/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_inter_trans/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_inter_trans/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_inter_trans/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_inter_trans/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_inter_trans/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_inter_trans/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_inter_trans/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_inter_trans/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_inter_trans/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_inter_trans/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_inter_trans_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_inter_trans OWNER TO oushu;

--
-- Name: ext_trans_ret_inter_trans_call_value_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_inter_trans_call_value_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_inter_trans_call_value_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_inter_trans_call_value; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_inter_trans_call_value (
    trans_id text,
    inter_index integer,
    call_index integer,
    call_value bigint,
    token_id text
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_inter_trans_call_value/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_inter_trans_call_value/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_inter_trans_call_value/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_inter_trans_call_value/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_inter_trans_call_value/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_inter_trans_call_value/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_inter_trans_call_value/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_inter_trans_call_value/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_inter_trans_call_value/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_inter_trans_call_value/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_inter_trans_call_value/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_inter_trans_call_value/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_inter_trans_call_value_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_inter_trans_call_value OWNER TO oushu;

--
-- Name: ext_trans_ret_log_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_log_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_log_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_log; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_log (
    trans_id text,
    log_index integer,
    address text,
    data text
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_log/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_log/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_log/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_log/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_log/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_log/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_log/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_log/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_log/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_log/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_log/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_log/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_log_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_log OWNER TO oushu;

--
-- Name: ext_trans_ret_log_topics_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_log_topics_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_log_topics_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_log_topics; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_log_topics (
    trans_id text,
    log_index integer,
    topic_index integer,
    topic text
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_log_topics/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_log_topics/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_log_topics/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_log_topics/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_log_topics/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_log_topics/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_log_topics/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_log_topics/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_log_topics/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_log_topics/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_log_topics/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_log_topics/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_log_topics_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_log_topics OWNER TO oushu;

--
-- Name: ext_trans_ret_order_detail_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trans_ret_order_detail_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_ret_order_detail_errs OWNER TO oushu;

--
-- Name: ext_trans_ret_order_detail; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_ret_order_detail (
    trans_id text,
    order_index integer,
    makerorderid text,
    takerorderid text,
    fillsellquantity bigint,
    fillbuyquantity bigint
) LOCATION (
    'gpfdist://tron1:8081/trans_ret/trans_ret_order_detail/0-13500000.csv',
    'gpfdist://tron1:8081/trans_ret/trans_ret_order_detail/13500000-15000000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_order_detail/15000000-16500000.csv',
    'gpfdist://tron2:8081/trans_ret/trans_ret_order_detail/16500000-18000000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_order_detail/18000000-19500000.csv',
    'gpfdist://tron3:8081/trans_ret/trans_ret_order_detail/19500000-21000000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_order_detail/21000000-22500000.csv',
    'gpfdist://tron4:8081/trans_ret/trans_ret_order_detail/22500000-24000000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_order_detail/24000000-25500000.csv',
    'gpfdist://tron5:8081/trans_ret/trans_ret_order_detail/25500000-27000000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_order_detail/27000000-28500000.csv',
    'gpfdist://tron6:8081/trans_ret/trans_ret_order_detail/28500000-29617377.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_ret_order_detail_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_ret_order_detail OWNER TO oushu;

--
-- Name: ext_trans_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trans_v1_errs OWNER TO gpadmin;

--
-- Name: ext_trans_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_v1 (
    block_num bigint,
    trans_id text
) LOCATION (
    'gpfdist://tron1:8082/trans_v1/0-5000000.csv',
    'gpfdist://tron2:8082/trans_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/trans_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/trans_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/trans_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/trans_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trans_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trans_v1 OWNER TO gpadmin;

--
-- Name: ext_transfer_asset_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_transfer_asset_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_transfer_asset_contract_errs OWNER TO gpadmin;

--
-- Name: ext_transfer_asset_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_transfer_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    asset_name text,
    owner_address text,
    to_address text,
    amount bigint
) LOCATION (
    'gpfdist://tron1:8081/transfer_asset_contract/0-2500000.csv',
    'gpfdist://tron1:8081/transfer_asset_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/transfer_asset_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/transfer_asset_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/transfer_asset_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/transfer_asset_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/transfer_asset_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/transfer_asset_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/transfer_asset_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/transfer_asset_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/transfer_asset_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/transfer_asset_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_transfer_asset_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_transfer_asset_contract OWNER TO gpadmin;

--
-- Name: ext_transfer_asset_contract_old; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_transfer_asset_contract_old (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    asset_name text,
    owner_address text,
    to_address text,
    amount bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/transfer_asset_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/transfer_asset_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/transfer_asset_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/transfer_asset_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/transfer_asset_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/transfer_asset_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/transfer_asset_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/transfer_asset_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/transfer_asset_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/transfer_asset_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/transfer_asset_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/transfer_asset_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_transfer_asset_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_transfer_asset_contract_old OWNER TO gpadmin;

--
-- Name: ext_transfer_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_transfer_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_transfer_contract_errs OWNER TO gpadmin;

--
-- Name: ext_transfer_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_transfer_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    to_address text,
    amount bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/transfer_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/transfer_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/transfer_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/transfer_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/transfer_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/transfer_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/transfer_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/transfer_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/transfer_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/transfer_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/transfer_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/transfer_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_transfer_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_transfer_contract OWNER TO gpadmin;

--
-- Name: ext_trc20_from_to_amount; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trc20_from_to_amount (
    trans_id text,
    log_index integer,
    func_abbr text,
    from1 text,
    to1 text,
    amount text
) LOCATION (
    'gpfdist://tron1:8081/trc20/trc20_from_to_amount1.csv',
    'gpfdist://tron2:8081/trc20/trc20_from_to_amount2.csv',
    'gpfdist://tron3:8081/trc20/trc20_from_to_amount3.csv',
    'gpfdist://tron4:8081/trc20/trc20_from_to_amount4.csv',
    'gpfdist://tron5:8081/trc20/trc20_from_to_amount5.csv',
    'gpfdist://tron6:8081/trc20/trc20_from_to_amount6.csv'
) FORMAT 'csv' (delimiter E',' null E' ' escape E'"' quote E'"')
ENCODING 'UTF8';


ALTER EXTERNAL TABLE public.ext_trc20_from_to_amount OWNER TO oushu;

--
-- Name: ext_trc20_from_to_amount_conv_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trc20_from_to_amount_conv_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trc20_from_to_amount_conv_errs OWNER TO oushu;

--
-- Name: ext_trc20_from_to_amount_conv; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trc20_from_to_amount_conv (
    trans_id text,
    log_index integer,
    func_abbr text,
    from1 text,
    to1 text,
    amount text
) LOCATION (
    'gpfdist://tron1:8081/trc20/trc20_from_to_amount_conv_1.csv',
    'gpfdist://tron2:8081/trc20/trc20_from_to_amount_conv_2.csv',
    'gpfdist://tron3:8081/trc20/trc20_from_to_amount_conv_3.csv',
    'gpfdist://tron4:8081/trc20/trc20_from_to_amount_conv_4.csv',
    'gpfdist://tron5:8081/trc20/trc20_from_to_amount_conv_5.csv',
    'gpfdist://tron6:8081/trc20/trc20_from_to_amount_conv_6.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trc20_from_to_amount_conv_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trc20_from_to_amount_conv OWNER TO oushu;

--
-- Name: ext_trc20_from_to_amount_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE ext_trc20_from_to_amount_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trc20_from_to_amount_errs OWNER TO oushu;

--
-- Name: ext_trigger_smart_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trigger_smart_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_trigger_smart_contract_errs OWNER TO gpadmin;

--
-- Name: ext_trigger_smart_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trigger_smart_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    call_value bigint,
    data text,
    call_token_value bigint,
    token_id bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trigger_smart_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/trigger_smart_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/trigger_smart_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trigger_smart_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trigger_smart_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trigger_smart_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trigger_smart_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trigger_smart_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trigger_smart_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trigger_smart_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trigger_smart_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trigger_smart_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_trigger_smart_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_trigger_smart_contract OWNER TO gpadmin;

--
-- Name: ext_unfreeze_asset_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_unfreeze_asset_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_unfreeze_asset_contract_errs OWNER TO gpadmin;

--
-- Name: ext_unfreeze_asset_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_unfreeze_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/unfreeze_asset_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/unfreeze_asset_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/unfreeze_asset_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/unfreeze_asset_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/unfreeze_asset_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/unfreeze_asset_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/unfreeze_asset_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/unfreeze_asset_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/unfreeze_asset_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/unfreeze_asset_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/unfreeze_asset_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/unfreeze_asset_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_unfreeze_asset_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_unfreeze_asset_contract OWNER TO gpadmin;

--
-- Name: ext_unfreeze_balance_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_unfreeze_balance_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_unfreeze_balance_contract_errs OWNER TO gpadmin;

--
-- Name: ext_unfreeze_balance_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_unfreeze_balance_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    resource integer,
    receiver_address text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/unfreeze_balance_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/unfreeze_balance_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/unfreeze_balance_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/unfreeze_balance_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/unfreeze_balance_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/unfreeze_balance_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/unfreeze_balance_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/unfreeze_balance_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/unfreeze_balance_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/unfreeze_balance_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/unfreeze_balance_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/unfreeze_balance_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_unfreeze_balance_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_unfreeze_balance_contract OWNER TO gpadmin;

--
-- Name: ext_update_asset_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_update_asset_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_update_asset_contract_errs OWNER TO gpadmin;

--
-- Name: ext_update_asset_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_update_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    description text,
    url text,
    new_limit bigint,
    new_public_limit bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/update_asset_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/update_asset_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/update_asset_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/update_asset_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/update_asset_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/update_asset_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/update_asset_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/update_asset_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/update_asset_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/update_asset_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/update_asset_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/update_asset_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_update_asset_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_update_asset_contract OWNER TO gpadmin;

--
-- Name: ext_update_brokerage_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_update_brokerage_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_update_brokerage_contract_errs OWNER TO gpadmin;

--
-- Name: ext_update_brokerage_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_update_brokerage_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    brokerage integer
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/update_brokerage_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/update_brokerage_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/update_brokerage_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/update_brokerage_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/update_brokerage_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/update_brokerage_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/update_brokerage_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/update_brokerage_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/update_brokerage_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/update_brokerage_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/update_brokerage_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/update_brokerage_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_update_brokerage_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_update_brokerage_contract OWNER TO gpadmin;

--
-- Name: ext_update_energy_limit_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_update_energy_limit_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_update_energy_limit_contract_errs OWNER TO gpadmin;

--
-- Name: ext_update_energy_limit_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_update_energy_limit_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    origin_energy_limit bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/update_energy_limit_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/update_energy_limit_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/update_energy_limit_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/update_energy_limit_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/update_energy_limit_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/update_energy_limit_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/update_energy_limit_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/update_energy_limit_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/update_energy_limit_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/update_energy_limit_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/update_energy_limit_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/update_energy_limit_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_update_energy_limit_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_update_energy_limit_contract OWNER TO gpadmin;

--
-- Name: ext_update_setting_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_update_setting_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_update_setting_contract_errs OWNER TO gpadmin;

--
-- Name: ext_update_setting_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_update_setting_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    consume_user_resource_percent bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/update_setting_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/update_setting_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/update_setting_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/update_setting_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/update_setting_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/update_setting_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/update_setting_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/update_setting_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/update_setting_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/update_setting_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/update_setting_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/update_setting_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_update_setting_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_update_setting_contract OWNER TO gpadmin;

--
-- Name: ext_vote_asset_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_vote_asset_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_vote_asset_contract_errs OWNER TO gpadmin;

--
-- Name: ext_vote_asset_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_vote_asset_contract (
    trans_id text,
    ret integer,
    bytes_hex text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/vote_asset_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/vote_asset_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/vote_asset_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/vote_asset_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/vote_asset_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/vote_asset_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/vote_asset_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/vote_asset_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/vote_asset_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/vote_asset_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/vote_asset_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/vote_asset_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_vote_asset_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_vote_asset_contract OWNER TO gpadmin;

--
-- Name: ext_vote_asset_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_vote_asset_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_vote_asset_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_vote_asset_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_vote_asset_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    support boolean,
    count integer
) LOCATION (
    'gpfdist://tron1:8082/vote_asset_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/vote_asset_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/vote_asset_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/vote_asset_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/vote_asset_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/vote_asset_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_vote_asset_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_vote_asset_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_vote_asset_contract_vote_address_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_vote_asset_contract_vote_address_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_vote_asset_contract_vote_address_v1_errs OWNER TO gpadmin;

--
-- Name: ext_vote_asset_contract_vote_address_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_vote_asset_contract_vote_address_v1 (
    trans_id text,
    vote_address text
) LOCATION (
    'gpfdist://tron1:8082/vote_asset_contract_vote_address_v1/0-5000000.csv',
    'gpfdist://tron2:8082/vote_asset_contract_vote_address_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/vote_asset_contract_vote_address_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/vote_asset_contract_vote_address_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/vote_asset_contract_vote_address_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/vote_asset_contract_vote_address_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_vote_asset_contract_vote_address_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_vote_asset_contract_vote_address_v1 OWNER TO gpadmin;

--
-- Name: ext_vote_witness_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_vote_witness_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_vote_witness_contract_errs OWNER TO gpadmin;

--
-- Name: ext_vote_witness_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_vote_witness_contract (
    trans_id text,
    ret integer,
    bytes_hex text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/vote_witness_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/vote_witness_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/vote_witness_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/vote_witness_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/vote_witness_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/vote_witness_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/vote_witness_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/vote_witness_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/vote_witness_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/vote_witness_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/vote_witness_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/vote_witness_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_vote_witness_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_vote_witness_contract OWNER TO gpadmin;

--
-- Name: ext_vote_witness_contract_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_vote_witness_contract_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_vote_witness_contract_v1_errs OWNER TO gpadmin;

--
-- Name: ext_vote_witness_contract_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_vote_witness_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    support boolean,
    tmp_0 text
) LOCATION (
    'gpfdist://tron1:8082/vote_witness_contract_v1/0-5000000.csv',
    'gpfdist://tron2:8082/vote_witness_contract_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/vote_witness_contract_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/vote_witness_contract_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/vote_witness_contract_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/vote_witness_contract_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_vote_witness_contract_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_vote_witness_contract_v1 OWNER TO gpadmin;

--
-- Name: ext_vote_witness_contract_votes_v1_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_vote_witness_contract_votes_v1_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_vote_witness_contract_votes_v1_errs OWNER TO gpadmin;

--
-- Name: ext_vote_witness_contract_votes_v1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_vote_witness_contract_votes_v1 (
    trans_id text,
    vote_address text,
    bote_account bigint
) LOCATION (
    'gpfdist://tron1:8082/vote_witness_contract_votes_v1/0-5000000.csv',
    'gpfdist://tron2:8082/vote_witness_contract_votes_v1/5000000-10000000.csv',
    'gpfdist://tron3:8082/vote_witness_contract_votes_v1/10000000-15000000.csv',
    'gpfdist://tron4:8082/vote_witness_contract_votes_v1/15000000-20000000.csv',
    'gpfdist://tron5:8082/vote_witness_contract_votes_v1/20000000-25000000.csv',
    'gpfdist://tron6:8082/vote_witness_contract_votes_v1/25000000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_vote_witness_contract_votes_v1_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_vote_witness_contract_votes_v1 OWNER TO gpadmin;

--
-- Name: ext_withdraw_balance_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_withdraw_balance_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_withdraw_balance_contract_errs OWNER TO gpadmin;

--
-- Name: ext_withdraw_balance_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_withdraw_balance_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/withdraw_balance_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/withdraw_balance_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/withdraw_balance_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/withdraw_balance_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/withdraw_balance_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/withdraw_balance_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/withdraw_balance_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/withdraw_balance_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/withdraw_balance_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/withdraw_balance_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/withdraw_balance_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/withdraw_balance_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_withdraw_balance_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_withdraw_balance_contract OWNER TO gpadmin;

--
-- Name: ext_witness_create_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_witness_create_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_witness_create_contract_errs OWNER TO gpadmin;

--
-- Name: ext_witness_create_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_witness_create_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    url text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/witness_create_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/witness_create_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/witness_create_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/witness_create_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/witness_create_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/witness_create_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/witness_create_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/witness_create_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/witness_create_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/witness_create_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/witness_create_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/witness_create_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_witness_create_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_witness_create_contract OWNER TO gpadmin;

--
-- Name: ext_witness_update_contract_errs; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_witness_update_contract_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.ext_witness_update_contract_errs OWNER TO gpadmin;

--
-- Name: ext_witness_update_contract; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_witness_update_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    update_url text
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/witness_update_contract/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/witness_update_contract/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/witness_update_contract/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/witness_update_contract/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/witness_update_contract/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/witness_update_contract/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/witness_update_contract/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/witness_update_contract/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/witness_update_contract/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/witness_update_contract/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/witness_update_contract/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/witness_update_contract/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.ext_witness_update_contract_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE public.ext_witness_update_contract OWNER TO gpadmin;

--
-- Name: father; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE father (
    fid integer,
    name character varying(10),
    oid integer
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.father OWNER TO oushu;

--
-- Name: filter_subtract_from; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE filter_subtract_from (
    ida text,
    idb text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.filter_subtract_from OWNER TO oushu;

--
-- Name: fm; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE fm (
    id integer,
    col2 integer[]
)FORMAT 'csv';


ALTER EXTERNAL TABLE public.fm OWNER TO gpadmin;

--
-- Name: freeze_balance_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE freeze_balance_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    frozen_balance bigint,
    frozen_duration bigint,
    resource integer,
    receiver_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.freeze_balance_contract OWNER TO gpadmin;

--
-- Name: from_subtract_filter; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE from_subtract_filter (
    ida text,
    idb text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.from_subtract_filter OWNER TO oushu;

--
-- Name: hash_trans; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE hash_trans (
    id text,
    trans_time text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (id);


ALTER TABLE public.hash_trans OWNER TO oushu;

--
-- Name: hash_trc20_from_to_amount_conv; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE hash_trc20_from_to_amount_conv (
    trans_id text,
    log_index integer,
    func_abbr text,
    from1 text,
    to1 text,
    amount text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.hash_trc20_from_to_amount_conv OWNER TO gpadmin;

--
-- Name: hash_trc20_his_step1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE hash_trc20_his_step1 (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    from_addr text,
    to_addr text,
    amount text,
    result integer,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.hash_trc20_his_step1 OWNER TO gpadmin;

--
-- Name: hash_trc20_token; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE hash_trc20_token (
    id integer NOT NULL,
    issue_ts integer,
    symbol text,
    contract_address text,
    gain text,
    home_page text,
    token_desc text,
    price_trx integer,
    git_hub text,
    price text,
    total_supply_with_decimals text,
    vip boolean,
    email text,
    icon_url text,
    total_supply bigint,
    level text,
    total_supply_str text,
    volume24h bigint,
    index bigint,
    contract_name text,
    volume bigint,
    issue_address text,
    holders_count bigint,
    decimals integer,
    name text,
    issue_time text,
    tokentype text,
    white_paper text,
    social_media text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (contract_address);


ALTER TABLE public.hash_trc20_token OWNER TO oushu;

--
-- Name: hash_trc20_trans_ret; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE hash_trc20_trans_ret (
    id text,
    fee bigint,
    block_number bigint,
    block_timestamp bigint,
    contract_address text,
    receipt_energy_usage bigint,
    receipt_energy_fee bigint,
    receipt_origin_energy_usage bigint,
    receipt_energy_usage_total bigint,
    receipt_net_usage bigint,
    receipt_net_fee bigint,
    receipt_result integer,
    result integer,
    resmessage text,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    packing_fee bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (id);


ALTER TABLE public.hash_trc20_trans_ret OWNER TO gpadmin;

--
-- Name: hash_trc20_trans_ret_log_topics_filter; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE hash_trc20_trans_ret_log_topics_filter (
    trans_id text,
    log_index integer,
    func_abbr text,
    func_name text,
    func_hash text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.hash_trc20_trans_ret_log_topics_filter OWNER TO oushu;

--
-- Name: hash_trigger_smart_contract; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE hash_trigger_smart_contract (
    trans_id text,
    owner_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.hash_trigger_smart_contract OWNER TO oushu;

--
-- Name: market_cancel_order_contract; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE market_cancel_order_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    order_id text
)FORMAT 'csv';


ALTER EXTERNAL TABLE public.market_cancel_order_contract OWNER TO oushu;

--
-- Name: market_cancel_order_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE market_cancel_order_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    order_id text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.market_cancel_order_contract_v1 OWNER TO gpadmin;

--
-- Name: market_sell_asset_contract; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE market_sell_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    sell_token_id text,
    sell_token_quantity bigint,
    buy_token_id text,
    buy_token_quantity bigint
)FORMAT 'csv';


ALTER EXTERNAL TABLE public.market_sell_asset_contract OWNER TO oushu;

--
-- Name: market_sell_asset_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE market_sell_asset_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    sell_token_id text,
    sell_token_quantity bigint,
    buy_token_id text,
    buy_token_quantity bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.market_sell_asset_contract_v1 OWNER TO gpadmin;

--
-- Name: orc_t_ethereum_erc20; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_erc20 (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_t_ethereum_erc20 OWNER TO gpadmin;

--
-- Name: orc_usdt_trans_ret_log; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE orc_usdt_trans_ret_log (
    trans_id text,
    log_index integer,
    address text,
    data text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_usdt_trans_ret_log OWNER TO oushu;

--
-- Name: orc_usdt_trans_ret_log_topics; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE orc_usdt_trans_ret_log_topics (
    trans_id text,
    log_index integer,
    topic_index integer,
    topic text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_usdt_trans_ret_log_topics OWNER TO oushu;

--
-- Name: orc_usdt_trans_ret_log_topics_filter; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE orc_usdt_trans_ret_log_topics_filter (
    trans_id text,
    log_index integer,
    func_name text,
    func_hash text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_usdt_trans_ret_log_topics_filter OWNER TO oushu;

--
-- Name: orc_usdt_trans_ret_log_topics_filter_amount; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE orc_usdt_trans_ret_log_topics_filter_amount (
    trans_id text,
    log_index integer,
    amount text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_usdt_trans_ret_log_topics_filter_amount OWNER TO oushu;

--
-- Name: orc_usdt_trans_ret_log_topics_filter_from; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE orc_usdt_trans_ret_log_topics_filter_from (
    trans_id text,
    log_index integer,
    topic text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_usdt_trans_ret_log_topics_filter_from OWNER TO oushu;

--
-- Name: orc_usdt_trans_ret_log_topics_filter_to; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE orc_usdt_trans_ret_log_topics_filter_to (
    trans_id text,
    log_index integer,
    topic text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.orc_usdt_trans_ret_log_topics_filter_to OWNER TO oushu;

--
-- Name: participate_asset_issue_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE participate_asset_issue_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    to_address text,
    asset_name text,
    amount bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.participate_asset_issue_contract OWNER TO gpadmin;

--
-- Name: proposal_approve_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE proposal_approve_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    proposal_id bigint,
    is_add_approval boolean
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.proposal_approve_contract OWNER TO gpadmin;

--
-- Name: proposal_create_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE proposal_create_contract (
    trans_id text,
    ret integer,
    bytes_hex text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.proposal_create_contract OWNER TO gpadmin;

--
-- Name: proposal_create_contract_parameters_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE proposal_create_contract_parameters_v1 (
    p_key bigint,
    p_value bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.proposal_create_contract_parameters_v1 OWNER TO gpadmin;

--
-- Name: proposal_create_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE proposal_create_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.proposal_create_contract_v1 OWNER TO gpadmin;

--
-- Name: proposal_delete_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE proposal_delete_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    proposal_id bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.proposal_delete_contract OWNER TO gpadmin;

--
-- Name: set_account_id_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE set_account_id_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    account_id text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.set_account_id_contract OWNER TO gpadmin;

--
-- Name: shielded_transfer_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE shielded_transfer_contract (
    trans_id text,
    ret integer,
    bytes_hex text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.shielded_transfer_contract OWNER TO gpadmin;

--
-- Name: shielded_transfer_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE shielded_transfer_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    transparent_from_address text,
    from_amount bigint,
    binding_signature text,
    transparent_to_address text,
    to_amount bigint,
    spend_description_value_commitment text,
    spend_description_anchor text,
    spend_description_nullifier text,
    spend_description_rk text,
    spend_description_zkproof text,
    spend_description_spend_authority_signature text,
    receive_description_value_commitment text,
    receive_description_note_commitment text,
    receive_description_epk text,
    receive_description_c_enc text,
    receive_description_c_out text,
    receive_description_zkproof text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.shielded_transfer_contract_v1 OWNER TO gpadmin;

--
-- Name: son; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE son (
    sid integer,
    name character varying(10),
    fid integer
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.son OWNER TO oushu;

--
-- Name: t; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE t (
    a integer[]
) LOCATION (
    'hdfs://tron6:9000/data'
) FORMAT 'csv'ENCODING 'UTF8';


ALTER EXTERNAL TABLE public.t OWNER TO gpadmin;

--
-- Name: t_TJqRY6aMvh9ae3sKy7SFcvX2PvexNZ9Cs6; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE "t_TJqRY6aMvh9ae3sKy7SFcvX2PvexNZ9Cs6" (
    trans_id text,
    block_num bigint,
    trans_time timestamp with time zone,
    trans_type text,
    is_trx boolean,
    from_address text,
    to_address text,
    amount real
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public."t_TJqRY6aMvh9ae3sKy7SFcvX2PvexNZ9Cs6" OWNER TO oushu;

--
-- Name: t_ao; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_ao (
    id integer,
    col2 integer[]
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.t_ao OWNER TO gpadmin;

--
-- Name: t_arr; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE t_arr (
    id integer,
    col02 integer[]
) LOCATION (
    'hdfs://tron6:9000/data'
) FORMAT 'csv'ENCODING 'UTF8';


ALTER EXTERNAL TABLE public.t_arr OWNER TO gpadmin;

--
-- Name: t_array; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_array (
    c1 integer,
    c2 integer[]
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.t_array OWNER TO gpadmin;

--
-- Name: t_ha1; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE t_ha1 (
    c text
) LOCATION (
    'hdfs://hacluster/hawq/default_filespace'
) FORMAT 'csv'ENCODING 'UTF8';


ALTER EXTERNAL TABLE public.t_ha1 OWNER TO gpadmin;

--
-- Name: t_hw; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE t_hw (
    c text
) LOCATION (
    'hdfs://hd03:25000/hawq/default_filespace'
) FORMAT 'csv'ENCODING 'UTF8';


ALTER EXTERNAL TABLE public.t_hw OWNER TO gpadmin;

--
-- Name: t_trans; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_trans (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_bytes text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.t_trans OWNER TO gpadmin;

--
-- Name: test; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE test (
    a integer,
    b text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.test OWNER TO oushu;

--
-- Name: tmp_trc20_token_hex; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE tmp_trc20_token_hex (
    id integer,
    issue_ts integer,
    symbol text,
    contract_address text,
    gain text,
    home_page text,
    token_desc text,
    price_trx integer,
    git_hub text,
    price text,
    total_supply_with_decimals text,
    vip boolean,
    email text,
    icon_url text,
    total_supply bigint,
    level text,
    total_supply_str text,
    volume24h bigint,
    index bigint,
    contract_name text,
    volume bigint,
    issue_address text,
    holders_count bigint,
    decimals integer,
    name text,
    issue_time text,
    tokentype text,
    white_paper text,
    social_media text,
    hex_addr text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.tmp_trc20_token_hex OWNER TO oushu;

--
-- Name: tmp_usdt_trc20; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE tmp_usdt_trc20 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    call_value bigint,
    data text,
    call_token_value bigint,
    token_id bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.tmp_usdt_trc20 OWNER TO oushu;

--
-- Name: token_addr_hex_base58; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE token_addr_hex_base58 (
    hex text,
    base58 text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.token_addr_hex_base58 OWNER TO oushu;

--
-- Name: trans; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans OWNER TO oushu;

--
-- Name: trans0629; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans0629 (
    id text,
    blocknum text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans0629 OWNER TO oushu;

--
-- Name: trans0630; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans0630 (
    id text,
    blocknum text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans0630 OWNER TO oushu;

--
-- Name: trans_155; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trans_155 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_bytes text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_155 OWNER TO gpadmin;

--
-- Name: trans_158; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_158 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_bytes text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_158 OWNER TO oushu;

--
-- Name: trans_4449; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_4449 (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_bytes text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_4449 OWNER TO oushu;

--
-- Name: trans_auths; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trans_auths (
    trans_id text,
    account_address text,
    account_name text,
    permission_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_auths OWNER TO gpadmin;

--
-- Name: trans_block_coount; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_block_coount (
    block_num bigint,
    trans_count bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_block_coount OWNER TO oushu;

--
-- Name: trans_block_coount_not_equal; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_block_coount_not_equal (
    block_num_b bigint,
    block_num_t bigint,
    tx_count_b integer,
    tx_count_t bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_block_coount_not_equal OWNER TO oushu;

--
-- Name: trans_block_count; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_block_count (
    block_num bigint,
    trans_count bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_block_count OWNER TO oushu;

--
-- Name: trans_block_count_compare; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_block_count_compare (
    block_num_b bigint,
    block_num_t bigint,
    tx_count_b integer,
    tx_count_t bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_block_count_compare OWNER TO oushu;

--
-- Name: trans_errors; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trans_errors (
    id text,
    block_hash text,
    block_num bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_errors OWNER TO gpadmin;

--
-- Name: trans_id_dup; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_id_dup (
    id text,
    count bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_id_dup OWNER TO oushu;

--
-- Name: trans_lack; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_lack (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_bytes text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_lack OWNER TO oushu;

--
-- Name: trans_market_order_detail; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trans_market_order_detail (
    trans_id text,
    makerorderid text,
    taker_order_id text,
    fill_sell_quantity bigint,
    fill_buy_quantity bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_market_order_detail OWNER TO gpadmin;

--
-- Name: trans_reimport_errs; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_reimport_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_reimport_errs OWNER TO oushu;

--
-- Name: trans_reimport; Type: EXTERNAL TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE trans_reimport (
    id text,
    block_hash text,
    block_num bigint,
    fee bigint,
    ret integer,
    contract_type integer,
    contract_ret integer,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    ref_block_bytes text,
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) LOCATION (
    'gpfdist://tron1:8081/trans_reparse/trans/22500000-23000000.csv',
    'gpfdist://tron1:8081/trans_reparse/trans/23000000-23500000.csv',
    'gpfdist://tron2:8081/trans_reparse/trans/23500000-24000000.csv',
    'gpfdist://tron2:8081/trans_reparse/trans/24000000-24500000.csv',
    'gpfdist://tron3:8081/trans_reparse/trans/24500000-25000000.csv',
    'gpfdist://tron3:8081/trans_reparse/trans/25000000-25500000.csv',
    'gpfdist://tron4:8081/trans_reparse/trans/25500000-26000000.csv',
    'gpfdist://tron4:8081/trans_reparse/trans/26000000-26500000.csv',
    'gpfdist://tron5:8081/trans_reparse/trans/26500000-27000000.csv',
    'gpfdist://tron5:8081/trans_reparse/trans/27000000-27500000.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO public.trans_reimport_errs SEGMENT REJECT LIMIT 100000 ROWS;


ALTER EXTERNAL TABLE public.trans_reimport OWNER TO oushu;

--
-- Name: trans_ret; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret (
    id text,
    fee bigint,
    block_number bigint,
    block_timestamp bigint,
    contract_address text,
    receipt_energy_usage bigint,
    receipt_energy_fee bigint,
    receipt_origin_energy_usage bigint,
    receipt_energy_usage_total bigint,
    receipt_net_usage bigint,
    receipt_net_fee bigint,
    receipt_result integer,
    result integer,
    resmessage text,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    packing_fee bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret OWNER TO oushu;

--
-- Name: trans_ret_contract_result; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_contract_result (
    trans_id text,
    result_index integer,
    result text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_contract_result OWNER TO oushu;

--
-- Name: trans_ret_error; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_error (
    type text,
    id text,
    err text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_error OWNER TO oushu;

--
-- Name: trans_ret_inter_trans; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_inter_trans (
    trans_id text,
    inter_index integer,
    hash text,
    caller_address text,
    transferto_address text,
    note text,
    rejected boolean
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_inter_trans OWNER TO oushu;

--
-- Name: trans_ret_inter_trans_call_value; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_inter_trans_call_value (
    trans_id text,
    inter_index integer,
    call_index integer,
    call_value bigint,
    token_id text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_inter_trans_call_value OWNER TO oushu;

--
-- Name: trans_ret_log; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_log (
    trans_id text,
    log_index integer,
    address text,
    data text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_log OWNER TO oushu;

--
-- Name: trans_ret_log_token_address; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_log_token_address (
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_log_token_address OWNER TO oushu;

--
-- Name: trans_ret_log_topics; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_log_topics (
    trans_id text,
    log_index integer,
    topic_index integer,
    topic text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_log_topics OWNER TO oushu;

--
-- Name: trans_ret_order_detail; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_ret_order_detail (
    trans_id text,
    order_index integer,
    makerorderid text,
    takerorderid text,
    fillsellquantity bigint,
    fillbuyquantity bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_ret_order_detail OWNER TO oushu;

--
-- Name: trans_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trans_v1 (
    block_num bigint,
    trans_id text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trans_v1 OWNER TO gpadmin;

--
-- Name: transfer_asset_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE transfer_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    asset_name text,
    owner_address text,
    to_address text,
    amount bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.transfer_asset_contract OWNER TO gpadmin;

--
-- Name: transfer_asset_contract_old; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE transfer_asset_contract_old (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    asset_name text,
    owner_address text,
    to_address text,
    amount bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.transfer_asset_contract_old OWNER TO gpadmin;

--
-- Name: transfer_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE transfer_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    to_address text,
    amount bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.transfer_contract OWNER TO gpadmin;

--
-- Name: trc20_fm; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_fm (
    trans_id text,
    trans_time timestamp with time zone,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount text,
    func_abbr text,
    result integer,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (token_address);


ALTER TABLE public.trc20_fm OWNER TO oushu;

--
-- Name: trc20_from_to; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_from_to (
    trans_id text,
    log_index integer,
    func_abbr text,
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_from_to OWNER TO oushu;

--
-- Name: trc20_from_to_amount; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_from_to_amount (
    trans_id text,
    log_index integer,
    func_abbr text,
    from1 text,
    to1 text,
    amount text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_from_to_amount OWNER TO oushu;

--
-- Name: trc20_from_to_amount_conv; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_from_to_amount_conv (
    trans_id text,
    log_index integer,
    func_abbr text,
    from1 text,
    to1 text,
    amount text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_from_to_amount_conv OWNER TO oushu;

--
-- Name: trc20_func_hash; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_func_hash (
    func_hash text,
    func_name text,
    func_abbr text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_func_hash OWNER TO oushu;

--
-- Name: trc20_his_final; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_final (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount numeric,
    func_abbr text,
    result integer,
    token_address text,
    token_index bigint,
    token_name text,
    token_decimal integer
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_his_final OWNER TO oushu;

--
-- Name: trc20_his_final_random; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_final_random (
    trans_time timestamp with time zone,
    block_timestamp timestamp with time zone
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_his_final_random OWNER TO oushu;

--
-- Name: trc20_his_final_v1; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_final_v1 (
    trans_id text,
    trans_time timestamp with time zone,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount numeric,
    func_abbr text,
    result integer,
    token_address text,
    token_symbol text,
    token_index bigint,
    token_name text,
    token_decimal integer
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_his_final_v1 OWNER TO oushu;

--
-- Name: trc20_his_step0; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_step0 (
    trans_id text,
    log_index integer,
    from_addr text,
    to_addr text,
    amount text,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.trc20_his_step0 OWNER TO oushu;

--
-- Name: trc20_his_step1; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_step1 (
    trans_id text,
    log_index integer,
    block_number bigint,
    block_timestamp timestamp with time zone,
    from_addr text,
    to_addr text,
    amount text,
    result integer,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.trc20_his_step1 OWNER TO oushu;

--
-- Name: trc20_his_step2; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_step2 (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    from_addr text,
    to_addr text,
    amount text,
    func_abbr text,
    result integer,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.trc20_his_step2 OWNER TO oushu;

--
-- Name: trc20_his_step3; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_step3 (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount text,
    func_abbr text,
    result integer,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (trans_id);


ALTER TABLE public.trc20_his_step3 OWNER TO oushu;

--
-- Name: trc20_his_step4; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_his_step4 (
    trans_id text,
    trans_time timestamp with time zone,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount text,
    func_abbr text,
    result integer,
    token_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (token_address);


ALTER TABLE public.trc20_his_step4 OWNER TO oushu;

--
-- Name: trc20_token; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_token (
    id integer NOT NULL,
    issue_ts integer,
    symbol text,
    contract_address text,
    gain text,
    home_page text,
    token_desc text,
    price_trx integer,
    git_hub text,
    price text,
    total_supply_with_decimals text,
    vip boolean,
    email text,
    icon_url text,
    total_supply bigint,
    level text,
    total_supply_str text,
    volume24h bigint,
    index bigint,
    contract_name text,
    volume bigint,
    issue_address text,
    holders_count bigint,
    decimals integer,
    name text,
    issue_time text,
    tokentype text,
    white_paper text,
    social_media text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_token OWNER TO oushu;

--
-- Name: trc20_token_hex; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_token_hex (
    id integer,
    issue_ts integer,
    symbol text,
    contract_address text,
    gain text,
    home_page text,
    token_desc text,
    price_trx integer,
    git_hub text,
    price text,
    total_supply_with_decimals text,
    vip boolean,
    email text,
    icon_url text,
    total_supply bigint,
    level text,
    total_supply_str text,
    volume24h bigint,
    index bigint,
    contract_name text,
    volume bigint,
    issue_address text,
    holders_count bigint,
    decimals integer,
    name text,
    issue_time text,
    tokentype text,
    white_paper text,
    social_media text,
    hex_addr text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED BY (contract_address);


ALTER TABLE public.trc20_token_hex OWNER TO oushu;

--
-- Name: trc20_token_id_seq; Type: SEQUENCE; Schema: public; Owner: oushu
--

CREATE SEQUENCE trc20_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.trc20_token_id_seq OWNER TO oushu;

--
-- Name: trc20_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oushu
--

ALTER SEQUENCE trc20_token_id_seq OWNED BY trc20_token.id;


--
-- Name: trc20_trans_ret; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_trans_ret (
    id text,
    fee bigint,
    block_number bigint,
    block_timestamp bigint,
    contract_address text,
    receipt_energy_usage bigint,
    receipt_energy_fee bigint,
    receipt_origin_energy_usage bigint,
    receipt_energy_usage_total bigint,
    receipt_net_usage bigint,
    receipt_net_fee bigint,
    receipt_result integer,
    result integer,
    resmessage text,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    packing_fee bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_trans_ret OWNER TO oushu;

--
-- Name: trc20_trans_ret_log_topics; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_trans_ret_log_topics (
    trans_id text,
    log_index integer,
    topic_index integer,
    topic text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_trans_ret_log_topics OWNER TO oushu;

--
-- Name: trc20_trans_ret_log_topics_filter; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_trans_ret_log_topics_filter (
    trans_id text,
    log_index integer,
    func_abbr text,
    func_name text,
    func_hash text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_trans_ret_log_topics_filter OWNER TO oushu;

--
-- Name: trc20_trans_ret_log_topics_filter_amount; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_trans_ret_log_topics_filter_amount (
    trans_id text,
    log_index integer,
    amount text,
    func_abbr text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_trans_ret_log_topics_filter_amount OWNER TO oushu;

--
-- Name: trc20_trans_ret_log_topics_filter_from; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_trans_ret_log_topics_filter_from (
    trans_id text,
    log_index integer,
    topic text,
    func_abbr text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_trans_ret_log_topics_filter_from OWNER TO oushu;

--
-- Name: trc20_trans_ret_log_topics_filter_to; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE trc20_trans_ret_log_topics_filter_to (
    trans_id text,
    log_index integer,
    topic text,
    func_abbr text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trc20_trans_ret_log_topics_filter_to OWNER TO oushu;

--
-- Name: trigger_smart_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trigger_smart_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    call_value bigint,
    data text,
    call_token_value bigint,
    token_id bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.trigger_smart_contract OWNER TO gpadmin;

--
-- Name: ttt; Type: EXTERNAL TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ttt (
    c text
) LOCATION (
    'hdfs://hd03:25000/hawq/default_filespace'
) FORMAT 'csv'ENCODING 'UTF8';


ALTER EXTERNAL TABLE public.ttt OWNER TO gpadmin;

--
-- Name: unfreeze_asset_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE unfreeze_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.unfreeze_asset_contract OWNER TO gpadmin;

--
-- Name: unfreeze_balance_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE unfreeze_balance_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    resource integer,
    receiver_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.unfreeze_balance_contract OWNER TO gpadmin;

--
-- Name: update_asset_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE update_asset_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    description text,
    url text,
    new_limit bigint,
    new_public_limit bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.update_asset_contract OWNER TO gpadmin;

--
-- Name: update_brokerage_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE update_brokerage_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    brokerage integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.update_brokerage_contract OWNER TO gpadmin;

--
-- Name: update_energy_limit_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE update_energy_limit_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    origin_energy_limit bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.update_energy_limit_contract OWNER TO gpadmin;

--
-- Name: update_setting_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE update_setting_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    contract_address text,
    consume_user_resource_percent bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.update_setting_contract OWNER TO gpadmin;

--
-- Name: usdt_from_to_amount; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_from_to_amount (
    trans_id text,
    log_index integer,
    from1 text,
    to1 text,
    amount text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_from_to_amount OWNER TO oushu;

--
-- Name: usdt_from_to_amount_conv; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_from_to_amount_conv (
    trans_id text,
    log_index integer,
    from1 text,
    to1 text,
    amount text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_from_to_amount_conv OWNER TO oushu;

--
-- Name: usdt_func_hash; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_func_hash (
    func_hash text,
    func_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_func_hash OWNER TO oushu;

--
-- Name: usdt_his_final; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_his_final (
    trans_id text,
    trans_time timestamp with time zone,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount text,
    type text,
    result integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_his_final OWNER TO oushu;

--
-- Name: usdt_his_step1; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_his_step1 (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    from_addr text,
    to_addr text,
    amount text,
    result integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_his_step1 OWNER TO oushu;

--
-- Name: usdt_his_step2; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_his_step2 (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    from_addr text,
    to_addr text,
    amount text,
    type text,
    result integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_his_step2 OWNER TO oushu;

--
-- Name: usdt_his_step3; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_his_step3 (
    trans_id text,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount text,
    type text,
    result integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_his_step3 OWNER TO oushu;

--
-- Name: usdt_his_step4; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_his_step4 (
    trans_id text,
    trans_time timestamp with time zone,
    block_number bigint,
    block_timestamp timestamp with time zone,
    trigger_addr text,
    from_addr text,
    to_addr text,
    amount text,
    type text,
    result integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_his_step4 OWNER TO oushu;

--
-- Name: usdt_test; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_test (
    trans_id text,
    log_index integer,
    from1 text,
    to1 text,
    amount text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_test OWNER TO oushu;

--
-- Name: usdt_trans_id; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_trans_id (
    trans_id text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_trans_id OWNER TO oushu;

--
-- Name: usdt_trans_ret; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_trans_ret (
    id text,
    fee bigint,
    block_number bigint,
    block_timestamp bigint,
    contract_address text,
    receipt_energy_usage bigint,
    receipt_energy_fee bigint,
    receipt_origin_energy_usage bigint,
    receipt_energy_usage_total bigint,
    receipt_net_usage bigint,
    receipt_net_fee bigint,
    receipt_result integer,
    result integer,
    resmessage text,
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    packing_fee bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_trans_ret OWNER TO oushu;

--
-- Name: usdt_trans_ret_log; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_trans_ret_log (
    trans_id text,
    log_index integer,
    address text,
    data text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_trans_ret_log OWNER TO oushu;

--
-- Name: usdt_trans_ret_log_topics; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_trans_ret_log_topics (
    trans_id text,
    log_index integer,
    topic_index integer,
    topic text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.usdt_trans_ret_log_topics OWNER TO oushu;

--
-- Name: vote_asset_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE vote_asset_contract (
    trans_id text,
    ret integer,
    bytes_hex text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.vote_asset_contract OWNER TO gpadmin;

--
-- Name: vote_asset_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE vote_asset_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    support boolean,
    count integer
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.vote_asset_contract_v1 OWNER TO gpadmin;

--
-- Name: vote_asset_contract_vote_address_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE vote_asset_contract_vote_address_v1 (
    trans_id text,
    vote_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.vote_asset_contract_vote_address_v1 OWNER TO gpadmin;

--
-- Name: vote_witness_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE vote_witness_contract (
    trans_id text,
    ret integer,
    bytes_hex text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.vote_witness_contract OWNER TO gpadmin;

--
-- Name: vote_witness_contract_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE vote_witness_contract_v1 (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    support boolean,
    tmp_0 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.vote_witness_contract_v1 OWNER TO gpadmin;

--
-- Name: vote_witness_contract_votes_v1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE vote_witness_contract_votes_v1 (
    trans_id text,
    vote_address text,
    bote_account bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.vote_witness_contract_votes_v1 OWNER TO gpadmin;

--
-- Name: withdraw_balance_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE withdraw_balance_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.withdraw_balance_contract OWNER TO gpadmin;

--
-- Name: witness_create_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE witness_create_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    url text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.witness_create_contract OWNER TO gpadmin;

--
-- Name: witness_update_contract; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE witness_update_contract (
    trans_id text,
    ret integer,
    provider text,
    name text,
    permission_id integer,
    owner_address text,
    update_url text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE public.witness_update_contract OWNER TO gpadmin;

--
-- Name: wuhao_txids; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE wuhao_txids (
    txid text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.wuhao_txids OWNER TO oushu;

--
-- Name: zeng_withdraw_address; Type: TABLE; Schema: public; Owner: oushu; Tablespace: 
--

CREATE TABLE zeng_withdraw_address (
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE public.zeng_withdraw_address OWNER TO oushu;

SET search_path = ytf, pg_catalog;

--
-- Name: aaa; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE aaa (
    address text,
    cnt integer,
    cnt_tx integer,
    sum_value numeric(38,20),
    min_ts timestamp without time zone,
    max_ts timestamp without time zone,
    is_suspect text,
    exchange_name text,
    rn bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.aaa OWNER TO oushu;

--
-- Name: all_exchange; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE all_exchange (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.all_exchange OWNER TO gpadmin;

--
-- Name: appendix; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE appendix (
    ordernum text,
    uid text,
    way text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.appendix OWNER TO oushu;

--
-- Name: binance_bithumb_suspects; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE binance_bithumb_suspects (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_bithumb_suspects OWNER TO gpadmin;

--
-- Name: binance_bithumb_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE binance_bithumb_v2 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_bithumb_v2 OWNER TO gpadmin;

--
-- Name: binance_deposit; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE binance_deposit (
    user_id text,
    currency text,
    amount double precision,
    deposit_address text,
    source_address text,
    txid text,
    create_time text,
    status text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_deposit OWNER TO oushu;

--
-- Name: binance_deposit_txid_eth; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE binance_deposit_txid_eth (
    lower text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_deposit_txid_eth OWNER TO oushu;

--
-- Name: binance_upbit_suspects; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE binance_upbit_suspects (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_upbit_suspects OWNER TO gpadmin;

--
-- Name: binance_upbit_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE binance_upbit_v2 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_upbit_v2 OWNER TO gpadmin;

--
-- Name: binance_withdraw; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE binance_withdraw (
    user_id text,
    currency text,
    amount double precision,
    destination_address text,
    label_tag_memo text,
    txid text,
    apply_time text,
    status text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_withdraw OWNER TO oushu;

--
-- Name: binance_withdraw_txid_eth; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE binance_withdraw_txid_eth (
    lower text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.binance_withdraw_txid_eth OWNER TO oushu;

--
-- Name: bithumb_suspects; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE bithumb_suspects (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.bithumb_suspects OWNER TO gpadmin;

--
-- Name: bithumb_suspects1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE bithumb_suspects1 (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.bithumb_suspects1 OWNER TO gpadmin;

--
-- Name: block; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE block (
    block_basic_reward text,
    block_hash text,
    block_height text,
    block_reward text,
    block_reward_percentage text,
    block_reward_rmb text,
    block_reward_usd text,
    block_size text,
    block_time_in_sec text,
    created_ts text,
    difficulty text,
    extra_data text,
    extra_data_decoded text,
    fee text,
    fee_rmb text,
    fee_usd text,
    gas_avg_price text,
    gas_limit text,
    gas_used text,
    gas_used_percentage text,
    miner_hash text,
    miner_icon_url text,
    miner_name text,
    nonce text,
    parent_hash text,
    time_in_sec text,
    total_difficulty text,
    total_internal_tx text,
    total_tx text,
    total_uncle text,
    uncle_ref_reward text,
    rksj text,
    sha3uncles text,
    transactionsroot text,
    stateroot text,
    logsbloom text,
    totalfees text,
    "timestamp" text,
    miner text,
    reward text,
    mineraddress text,
    minerextra text,
    mingasprice text,
    maxgasprice text,
    txfee text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.block OWNER TO gpadmin;

--
-- Name: block_ao; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE block_ao (
    block_basic_reward text,
    block_hash text,
    block_height text,
    block_reward text,
    block_reward_percentage text,
    block_reward_rmb text,
    block_reward_usd text,
    block_size text,
    block_time_in_sec text,
    created_ts text,
    difficulty text,
    extra_data text,
    extra_data_decoded text,
    fee text,
    fee_rmb text,
    fee_usd text,
    gas_avg_price text,
    gas_limit text,
    gas_used text,
    gas_used_percentage text,
    miner_hash text,
    miner_icon_url text,
    miner_name text,
    nonce text,
    parent_hash text,
    time_in_sec text,
    total_difficulty text,
    total_internal_tx text,
    total_tx text,
    total_uncle text,
    uncle_ref_reward text,
    rksj text,
    sha3uncles text,
    transactionsroot text,
    stateroot text,
    logsbloom text,
    totalfees text,
    "timestamp" text,
    miner text,
    reward text,
    mineraddress text,
    minerextra text,
    mingasprice text,
    maxgasprice text,
    txfee text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.block_ao OWNER TO oushu;

--
-- Name: block_ao_his; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE block_ao_his (
    block_basic_reward text,
    block_hash text,
    block_height text,
    block_reward text,
    block_reward_percentage text,
    block_reward_rmb text,
    block_reward_usd text,
    block_size text,
    block_time_in_sec text,
    created_ts text,
    difficulty text,
    extra_data text,
    extra_data_decoded text,
    fee text,
    fee_rmb text,
    fee_usd text,
    gas_avg_price text,
    gas_limit text,
    gas_used text,
    gas_used_percentage text,
    miner_hash text,
    miner_icon_url text,
    miner_name text,
    nonce text,
    parent_hash text,
    time_in_sec text,
    total_difficulty text,
    total_internal_tx text,
    total_tx text,
    total_uncle text,
    uncle_ref_reward text,
    rksj text,
    sha3uncles text,
    transactionsroot text,
    stateroot text,
    logsbloom text,
    totalfees text,
    "timestamp" text,
    miner text,
    reward text,
    mineraddress text,
    minerextra text,
    mingasprice text,
    maxgasprice text,
    txfee text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.block_ao_his OWNER TO oushu;

--
-- Name: block_orc_dup; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE block_orc_dup (
    block_height bigint,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.block_orc_dup OWNER TO oushu;

--
-- Name: caohs_sbling_trans; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_sbling_trans (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_sbling_trans OWNER TO oushu;

--
-- Name: caohs_sblings; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_sblings (
    from1 text,
    amount double precision,
    total_amount numeric,
    rate double precision
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_sblings OWNER TO oushu;

--
-- Name: caohs_sblings_other; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_sblings_other (
    from1 text,
    amount double precision,
    total_amount numeric,
    rate double precision
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_sblings_other OWNER TO oushu;

--
-- Name: caohs_sblings_suspects; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_sblings_suspects (
    transactionhash text,
    ts timestamp with time zone,
    from1 text,
    tag_name text,
    to1 text,
    "?column?" double precision,
    rate double precision
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_sblings_suspects OWNER TO oushu;

--
-- Name: caohs_sblings_tag; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_sblings_tag (
    from1 text,
    amount double precision,
    total_amount numeric,
    rate double precision,
    tag_name text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_sblings_tag OWNER TO oushu;

--
-- Name: caohs_sblings_tag_other; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_sblings_tag_other (
    from1 text,
    amount double precision,
    total_amount numeric,
    rate double precision,
    tag_name text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_sblings_tag_other OWNER TO oushu;

--
-- Name: caohs_transit_up_other; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_transit_up_other (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_transit_up_other OWNER TO oushu;

--
-- Name: caohs_transit_up_trans; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_transit_up_trans (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_transit_up_trans OWNER TO oushu;

--
-- Name: caohs_withdraw; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE caohs_withdraw (
    token_type text,
    address text,
    amount double precision,
    txid text,
    create_time text,
    update_time text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.caohs_withdraw OWNER TO oushu;

--
-- Name: dbjy; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE dbjy (
    tx_hash text,
    block_height text,
    created_ts text,
    time_in_sec text,
    sender_hash text,
    receiver_hash text,
    amount text,
    token_hash text,
    token_name text,
    token_decimal text,
    unit_name text,
    token_found text,
    sender_name text,
    receiver_name text,
    sender_type text,
    receiver_type text,
    token_url text,
    tx_type text,
    token_icon_url text,
    glaccount_hash text,
    rksj text,
    "timestamp" text,
    tokenaddress text,
    fromiscontract text,
    toiscontract text,
    tokenid text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.dbjy OWNER TO gpadmin;

--
-- Name: dbjy_ao; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE dbjy_ao (
    tx_hash text,
    block_height text,
    created_ts text,
    time_in_sec text,
    sender_hash text,
    receiver_hash text,
    amount text,
    token_hash text,
    token_name text,
    token_decimal text,
    unit_name text,
    token_found text,
    sender_name text,
    receiver_name text,
    sender_type text,
    receiver_type text,
    token_url text,
    tx_type text,
    token_icon_url text,
    glaccount_hash text,
    rksj text,
    "timestamp" text,
    tokenaddress text,
    fromiscontract text,
    toiscontract text,
    tokenid text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.dbjy_ao OWNER TO oushu;

--
-- Name: dbjy_ao_his; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE dbjy_ao_his (
    tx_hash text,
    block_height text,
    created_ts text,
    time_in_sec text,
    sender_hash text,
    receiver_hash text,
    amount text,
    token_hash text,
    token_name text,
    token_decimal text,
    unit_name text,
    token_found text,
    sender_name text,
    receiver_name text,
    sender_type text,
    receiver_type text,
    token_url text,
    tx_type text,
    token_icon_url text,
    glaccount_hash text,
    rksj text,
    "timestamp" text,
    tokenaddress text,
    fromiscontract text,
    toiscontract text,
    tokenid text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.dbjy_ao_his OWNER TO oushu;

--
-- Name: deposit_not_in; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE deposit_not_in (
    txid text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.deposit_not_in OWNER TO gpadmin;

--
-- Name: deposit_txids; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE deposit_txids (
    txid text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.deposit_txids OWNER TO gpadmin;

--
-- Name: deposit_withdraw_record; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE deposit_withdraw_record (
    address text,
    ordernum text,
    uid text,
    way text,
    coin text,
    "time" date,
    value text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.deposit_withdraw_record OWNER TO oushu;

--
-- Name: domestic_date_count; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE domestic_date_count (
    to1 text,
    exchange_domestic text,
    date_count bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.domestic_date_count OWNER TO oushu;

--
-- Name: domestic_statics; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE domestic_statics (
    to1 text,
    exchange_domestic text,
    domestic_trans_count bigint,
    domestic_trans_amount double precision,
    domestic_min_ts bigint,
    domestic_date_count bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.domestic_statics OWNER TO oushu;

--
-- Name: domestic_statics_overall; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE domestic_statics_overall (
    to1 text,
    all_domestic_trans_count numeric,
    all_domestic_trans_amount double precision,
    all_domestic_min_ts bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.domestic_statics_overall OWNER TO oushu;

--
-- Name: dup_tag_addr; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE dup_tag_addr (
    address text,
    tag_cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.dup_tag_addr OWNER TO oushu;

--
-- Name: eth_usdt_huobi_bithumb; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE eth_usdt_huobi_bithumb (
    to1 text,
    date_count bigint,
    amount numeric
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.eth_usdt_huobi_bithumb OWNER TO gpadmin;

--
-- Name: eth_usdt_okex_bithumb; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE eth_usdt_okex_bithumb (
    to1 text,
    date_count bigint,
    amount numeric
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.eth_usdt_okex_bithumb OWNER TO oushu;

--
-- Name: eth_usdt_okex_upbit; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE eth_usdt_okex_upbit (
    to1 text,
    date_count bigint,
    amount numeric
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.eth_usdt_okex_upbit OWNER TO oushu;

--
-- Name: exchange_domestic; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE exchange_domestic (
    name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.exchange_domestic OWNER TO oushu;

--
-- Name: exchange_domestic_addr; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE exchange_domestic_addr (
    exchange_name text,
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.exchange_domestic_addr OWNER TO oushu;

--
-- Name: exchange_overseas; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE exchange_overseas (
    name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.exchange_overseas OWNER TO oushu;

--
-- Name: exchange_overseas_addr; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE exchange_overseas_addr (
    exchange_name text,
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.exchange_overseas_addr OWNER TO oushu;

--
-- Name: exchange_overseas_addr1; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE exchange_overseas_addr1 (
    exchange_name text,
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.exchange_overseas_addr1 OWNER TO oushu;

--
-- Name: ext_block_errs; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_block_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.ext_block_errs OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_erc20_errs; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_t_ethereum_erc20_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.ext_t_ethereum_erc20_errs OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_erc20; Type: EXTERNAL TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_t_ethereum_erc20 (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text
) LOCATION (
    'gpfdist://tron1:8081/ERCT20/0to999999_ERC20Transaction.csv',
    'gpfdist://tron1:8081/ERCT20/1000000to1999999_ERC20Transaction.csv',
    'gpfdist://tron2:8081/ERCT20/2000000to2999999_ERC20Transaction.csv',
    'gpfdist://tron2:8081/ERCT20/3000000to3999999_ERC20Transaction.csv',
    'gpfdist://tron3:8081/ERCT20/4000000to4999999_ERC20Transaction.csv',
    'gpfdist://tron3:8081/ERCT20/5000000to5999999_ERC20Transaction.csv',
    'gpfdist://tron4:8081/ERCT20/6000000to6999999_ERC20Transaction.csv',
    'gpfdist://tron4:8081/ERCT20/7000000to7999999_ERC20Transaction.csv',
    'gpfdist://tron5:8081/ERCT20/9000000to9999999_ERC20Transaction.csv',
    'gpfdist://tron6:8081/ERCT20/10000000to10999999_ERC20Transaction.csv',
    'gpfdist://tron6:8081/ERCT20/11000000to11999999_ERC20Transaction.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO ytf.ext_t_ethereum_erc20_errs SEGMENT REJECT LIMIT 50000 ROWS;


ALTER EXTERNAL TABLE ytf.ext_t_ethereum_erc20 OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_internaltransactionerrs; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_t_ethereum_internaltransactionerrs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.ext_t_ethereum_internaltransactionerrs OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_internaltransaction; Type: EXTERNAL TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_t_ethereum_internaltransaction (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    typetraceaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text,
    callingfunction text,
    iserror text
) LOCATION (
    'gpfdist://tron1:8081/Internal/0to999999_InternalTransaction.csv',
    'gpfdist://tron1:8081/Internal/1000000to1999999_InternalTransaction.csv',
    'gpfdist://tron2:8081/Internal/2000000to2999999_InternalTransaction.csv',
    'gpfdist://tron2:8081/Internal/3000000to3999999_InternalTransaction.csv',
    'gpfdist://tron3:8081/Internal/4000000to4999999_InternalTransaction.csv',
    'gpfdist://tron3:8081/Internal/5000000to5999999_InternalTransaction.csv',
    'gpfdist://tron4:8081/Internal/6000000to6999999_InternalTransaction.csv',
    'gpfdist://tron4:8081/Internal/7000000to7999999_InternalTransaction.csv',
    'gpfdist://tron5:8081/Internal/8000000to8999999_InternalTransaction.csv',
    'gpfdist://tron5:8081/Internal/9000000to9999999_InternalTransaction.csv',
    'gpfdist://tron6:8081/Internal/10000000to10999999_InternalTransaction.csv',
    'gpfdist://tron6:8081/Internal/11000000to11999999_InternalTransaction.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO ytf.ext_t_ethereum_internaltransactionerrs SEGMENT REJECT LIMIT 1000 ROWS;


ALTER EXTERNAL TABLE ytf.ext_t_ethereum_internaltransaction OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_nmta_errs; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_t_ethereum_nmta_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.ext_t_ethereum_nmta_errs OWNER TO gpadmin;

--
-- Name: ext_t_ethereum_nmta; Type: EXTERNAL TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_t_ethereum_nmta (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text
) LOCATION (
    'gpfdist://tron1:8081/nmta/0to999999_NormalTransaction.csv',
    'gpfdist://tron1:8081/nmta/1000000to1999999_NormalTransaction.csv',
    'gpfdist://tron2:8081/nmta/2000000to2999999_NormalTransaction.csv',
    'gpfdist://tron2:8081/nmta/3000000to3999999_NormalTransaction.csv',
    'gpfdist://tron3:8081/nmta/4000000to4999999_NormalTransaction.csv',
    'gpfdist://tron3:8081/nmta/5000000to5999999_NormalTransaction.csv',
    'gpfdist://tron4:8081/nmta/6000000to6999999_NormalTransaction.csv',
    'gpfdist://tron4:8081/nmta/7000000to7999999_NormalTransaction.csv',
    'gpfdist://tron5:8081/nmta/8000000to8999999_NormalTransaction.csv',
    'gpfdist://tron5:8081/nmta/9000000to9999999_NormalTransaction.csv',
    'gpfdist://tron6:8081/nmta/10000000to10999999_NormalTransaction.csv',
    'gpfdist://tron6:8081/nmta/11000000to11999999_NormalTransaction.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO ytf.ext_t_ethereum_nmta_errs SEGMENT REJECT LIMIT 1000 ROWS;


ALTER EXTERNAL TABLE ytf.ext_t_ethereum_nmta OWNER TO gpadmin;

--
-- Name: ext_trans_market_order_detail_errs; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE ext_trans_market_order_detail_errs (
    cmdtime timestamp with time zone,
    relname text,
    filename text,
    linenum integer,
    bytenum integer,
    errmsg text,
    rawdata text,
    rawbytes bytea
)
WITH (errortable=true, appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.ext_trans_market_order_detail_errs OWNER TO gpadmin;

--
-- Name: ext_trans_market_order_detail; Type: EXTERNAL TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE WRITABLE EXTERNAL TABLE ext_trans_market_order_detail (
    trans_id text,
    makerorderid text,
    taker_order_id text,
    fill_sell_quantity bigint,
    fill_buy_quantity bigint
) LOCATION (
    'gpfdist://tron1:8081/block_parsed_0_250w/trans_market_order_detail/0-2500000.csv',
    'gpfdist://tron1:8081/block_parsed_250_500w/trans_market_order_detail/2500000-5000000.csv',
    'gpfdist://tron2:8081/block_parsed_500_750w/trans_market_order_detail/5000000-7500000.csv',
    'gpfdist://tron2:8081/block_parsed_750_1000w/trans_market_order_detail/7500000-10000000.csv',
    'gpfdist://tron3:8081/block_parsed_1000_1250w/trans_market_order_detail/10000000-12500000.csv',
    'gpfdist://tron3:8081/block_parsed_1250_1500w/trans_market_order_detail/12500000-15000000.csv',
    'gpfdist://tron4:8081/block_parsed_1500_1750w/trans_market_order_detail/15000000-17500000.csv',
    'gpfdist://tron4:8081/block_parsed_1750_2000w/trans_market_order_detail/17500000-20000000.csv',
    'gpfdist://tron5:8081/block_parsed_2000_2250w/trans_market_order_detail/20000000-22500000.csv',
    'gpfdist://tron5:8081/block_parsed_2250_2500w/trans_market_order_detail/22500000-25000000.csv',
    'gpfdist://tron6:8081/block_parsed_2500_2750w/trans_market_order_detail/25000000-27500000.csv',
    'gpfdist://tron6:8081/block_parsed_2750_3000w/trans_market_order_detail/27500000-29617378.csv'
) FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8'
LOG ERRORS INTO ytf.ext_trans_market_order_detail_errs SEGMENT REJECT LIMIT 10000 ROWS;


ALTER EXTERNAL TABLE ytf.ext_trans_market_order_detail OWNER TO gpadmin;

--
-- Name: huobi_bithumb_suspects; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE huobi_bithumb_suspects (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_bithumb_suspects OWNER TO gpadmin;

--
-- Name: huobi_bithumb_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE huobi_bithumb_v2 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_bithumb_v2 OWNER TO gpadmin;

--
-- Name: huobi_deposit_txid_eth; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE huobi_deposit_txid_eth (
    lower text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_deposit_txid_eth OWNER TO oushu;

--
-- Name: huobi_inout; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE huobi_inout (
    address text,
    txid text,
    uid text,
    "inout" text,
    token_type text,
    create_time text,
    amount double precision
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_inout OWNER TO oushu;

--
-- Name: huobi_upbit_suspects; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE huobi_upbit_suspects (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_upbit_suspects OWNER TO gpadmin;

--
-- Name: huobi_upbit_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE huobi_upbit_v2 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_upbit_v2 OWNER TO gpadmin;

--
-- Name: huobi_withdraw_txid_eth; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE huobi_withdraw_txid_eth (
    lower text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.huobi_withdraw_txid_eth OWNER TO oushu;

--
-- Name: internaltransaction; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE internaltransaction (
    blocknumber text,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text,
    rksj text,
    blockhash text,
    type text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.internaltransaction OWNER TO gpadmin;

--
-- Name: internaltransaction_ao; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE internaltransaction_ao (
    blocknumber text,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text,
    rksj text,
    blockhash text,
    type text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.internaltransaction_ao OWNER TO oushu;

--
-- Name: internaltransaction_ao_his; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE internaltransaction_ao_his (
    blocknumber text,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text,
    rksj text,
    blockhash text,
    type text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.internaltransaction_ao_his OWNER TO oushu;

--
-- Name: investigated; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE investigated (
    address text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.investigated OWNER TO oushu;

--
-- Name: name; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE name (
    hash text,
    name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.name OWNER TO gpadmin;

--
-- Name: okex_bithumb_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE okex_bithumb_v2 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_bithumb_v2 OWNER TO gpadmin;

--
-- Name: okex_bithumb_v21; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE okex_bithumb_v21 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_bithumb_v21 OWNER TO gpadmin;

--
-- Name: okex_deposit; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE okex_deposit (
    token_type text,
    address text,
    amount double precision,
    txid text,
    create_time text,
    update_time text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_deposit OWNER TO oushu;

--
-- Name: okex_deposit_txid_eth; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE okex_deposit_txid_eth (
    lower text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_deposit_txid_eth OWNER TO oushu;

--
-- Name: okex_upbit_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE okex_upbit_v2 (
    to1 text,
    date_count bigint,
    "转币次数" bigint,
    max_date text,
    min_date text,
    amount real,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_upbit_v2 OWNER TO gpadmin;

--
-- Name: okex_withdraw; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE okex_withdraw (
    token_type text,
    address text,
    amount double precision,
    txid text,
    create_time text,
    update_time text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_withdraw OWNER TO oushu;

--
-- Name: okex_withdraw_txid_eth; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE okex_withdraw_txid_eth (
    lower text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.okex_withdraw_txid_eth OWNER TO oushu;

--
-- Name: orc_okex_deposit_txid_eth; Type: TABLE; Schema: ytf; Owner: test; Tablespace: 
--

CREATE TABLE orc_okex_deposit_txid_eth (
    lower text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_okex_deposit_txid_eth OWNER TO test;

--
-- Name: orc_t_ethereum_block_qmr; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_block_qmr (
    id character varying(100),
    blocknumber character varying(100),
    "timestamp" character varying(100),
    size1 character varying(100),
    difficulty character varying(100),
    transactioncount character varying(100),
    mineraddress character varying(100),
    minerextra character varying(100),
    gaslimit character varying(100),
    gasused character varying(100),
    mingasprice character varying(100),
    maxgasprice character varying(100),
    avggasprice character varying(100),
    txfee character varying(100),
    rksj character varying(100),
    wjjmc character varying(100)
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_t_ethereum_block_qmr OWNER TO gpadmin;

--
-- Name: orc_t_ethereum_erc20; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_erc20 (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    tokenaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_t_ethereum_erc20 OWNER TO gpadmin;

--
-- Name: orc_t_ethereum_iet; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_iet (
    id character varying(100),
    blocknumber character varying(100),
    "timestamp" character varying(100),
    transactionhash character varying(500),
    tokenaddress character varying(100),
    from1 character varying(100),
    to1 character varying(100),
    fromiscontract character varying(100),
    toiscontract character varying(100),
    value character varying(100),
    rksj character varying(100),
    wjjmc character varying(100)
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_t_ethereum_iet OWNER TO gpadmin;

--
-- Name: orc_t_ethereum_internaltransaction; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_internaltransaction (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    typetraceaddress text,
    from1 text,
    to1 text,
    fromiscontract text,
    toiscontract text,
    value text,
    callingfunction text,
    iserror text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_t_ethereum_internaltransaction OWNER TO gpadmin;

--
-- Name: orc_t_ethereum_nm_ta; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_nm_ta (
    id text,
    blocknumber text,
    timestamp1 text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_t_ethereum_nm_ta OWNER TO gpadmin;

--
-- Name: orc_t_ethereum_nmta; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE orc_t_ethereum_nmta (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.orc_t_ethereum_nmta OWNER TO gpadmin;

--
-- Name: overseas_date_count; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE overseas_date_count (
    from1 text,
    exchange_overseas text,
    date_count bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.overseas_date_count OWNER TO oushu;

--
-- Name: overseas_statics; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE overseas_statics (
    from1 text,
    exchange_overseas text,
    overseas_trans_count bigint,
    overseas_trans_amount double precision,
    overseas_max_ts bigint,
    overseas_date_count bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.overseas_statics OWNER TO oushu;

--
-- Name: res; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE res (
    from1 text,
    to1 text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.res OWNER TO gpadmin;

--
-- Name: result_final; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE result_final (
    to1 text,
    exchange_name text,
    is_oversea text,
    transactionhash text,
    cnt_tag bigint,
    cnt_tx bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.result_final OWNER TO oushu;

--
-- Name: results_134; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE results_134 (
    to1 text,
    is_oversea text,
    cnt_tag bigint,
    cnt_tx bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.results_134 OWNER TO oushu;

--
-- Name: results_2; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE results_2 (
    to1 text,
    exchange_name text,
    transactionhash text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.results_2 OWNER TO oushu;

--
-- Name: results_2_v1; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE results_2_v1 (
    to1 text,
    exchange_name text,
    transactionhash text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.results_2_v1 OWNER TO oushu;

--
-- Name: single_tag_addr; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE single_tag_addr (
    address text,
    tag_cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.single_tag_addr OWNER TO oushu;

--
-- Name: statics_final; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final (
    to1 text,
    exchange_domestic text,
    exchange_overseas text,
    overseas_date_count bigint,
    domestic_date_count bigint,
    domestic_trans_count bigint,
    overseas_trans_count bigint,
    trans_count_all bigint,
    rate numeric,
    domestic_trans_amount double precision,
    overseas_trans_amount double precision,
    boarding_time timestamp with time zone,
    lastest_time timestamp with time zone,
    domestic_min_ts timestamp with time zone,
    overseas_max_ts timestamp with time zone,
    all_domestic_trans_amount double precision,
    all_domestic_trans_count numeric,
    to_timestamp timestamp with time zone
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final OWNER TO oushu;

--
-- Name: statics_final_en; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_en (
    "境外交易所过渡账户地址" text,
    "国内交易所" text,
    "国外交易所" text,
    "给境外指定交易所转币天数" bigint,
    "接受国内指定交易所转币天数" bigint,
    "指定国内交易所到1的交易次数 A" bigint,
    "过渡地址给境外指定交易所转币次数" bigint,
    "总交易次数" bigint,
    "与交易所交易次数占总交易次数比" bigint,
    "指定国内池到过渡地址的交易金额" double precision,
    "过渡地址到国外交易所的交易金额" double precision,
    "上链时间" timestamp with time zone,
    "过渡地址最新交易时间" timestamp with time zone,
    "国内交易所到过渡地址的首次交易时间" timestamp with time zone,
    "过渡地址到国外交易所的最新交易时间" timestamp with time zone,
    "国内所有交易所到过渡地址的交易总金额" double precision,
    "国内所有交易所到过渡地址的交易总次数" numeric,
    "与国内所有交易所最早交易时间" timestamp with time zone
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_en OWNER TO oushu;

--
-- Name: statics_final_en_v2; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_en_v2 (
    "境外交易所过渡账户地址" text,
    "国内交易所" text,
    "国外交易所" text,
    "给境外指定交易所转币天数" bigint,
    "接受国内指定交易所转币天数" bigint,
    "指定国内交易所到1的交易次数 A" bigint,
    "过渡地址给境外指定交易所转币次数" bigint,
    "总交易次数" bigint,
    "与交易所交易次数占总交易次数比" bigint,
    "指定国内池到过渡地址的交易金额" double precision,
    "过渡地址到国外交易所的交易金额" double precision,
    "上链时间" text,
    "过渡地址最新交易时间" text,
    "国内交易所到过渡地址的首次交易时间" timestamp with time zone,
    "过渡地址到国外交易所的最新交易时间" timestamp with time zone,
    "国内所有交易所到过渡地址的交易总金额" double precision,
    "国内所有交易所到过渡地址的交易总次数" numeric,
    "与国内所有交易所最早交易时间" bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_en_v2 OWNER TO oushu;

--
-- Name: statics_final_en_v4; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_en_v4 (
    "境外交易所过渡账户地址" text,
    "国内交易所" text,
    "国外交易所" text,
    "给境外指定交易所转币天数" bigint,
    "接受国内指定交易所转币天数" bigint,
    "指定国内交易所到1的交易次数 A" bigint,
    "过渡地址给境外指定交易所转币次数" bigint,
    "总交易次数" bigint,
    "与交易所交易次数占总交易次数比" bigint,
    "指定国内池到过渡地址的交易金额" double precision,
    "过渡地址到国外交易所的交易金额" double precision,
    "上链时间" timestamp with time zone,
    "过渡地址最新交易时间" timestamp with time zone,
    "国内交易所到过渡地址的首次交易时间" timestamp with time zone,
    "过渡地址到国外交易所的最新交易时间" timestamp with time zone,
    "国内所有交易所到过渡地址的交易总金额" double precision,
    "国内所有交易所到过渡地址的交易总次数" numeric,
    "与国内所有交易所最早交易时间" timestamp with time zone
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_en_v4 OWNER TO oushu;

--
-- Name: statics_final_investigated; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_investigated (
    to1 text,
    exchange_domestic text,
    exchange_overseas text,
    overseas_date_count bigint,
    domestic_date_count bigint,
    domestic_trans_count bigint,
    overseas_trans_count bigint,
    trans_count_all bigint,
    rate bigint,
    domestic_trans_amount double precision,
    overseas_trans_amount double precision,
    boarding_time timestamp with time zone,
    lastest_time timestamp with time zone,
    domestic_min_ts timestamp with time zone,
    overseas_max_ts timestamp with time zone,
    all_domestic_trans_amount double precision,
    all_domestic_trans_count numeric,
    to_timestamp timestamp with time zone,
    is_oversea text,
    transactionhash text,
    cnt_tag bigint,
    cnt_tx bigint,
    flag boolean
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_investigated OWNER TO oushu;

--
-- Name: statics_final_investigated_cn; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_investigated_cn (
    "境外交易所过渡账户地址" text,
    "国内交易所" text,
    "国外交易所" text,
    "给境外指定交易所转币天数" bigint,
    "接受国内指定交易所转币天数" bigint,
    "指定国内交易所到1的交易次数 A" bigint,
    "过渡地址给境外指定交易所转币次数" bigint,
    "总交易次数" bigint,
    "与交易所交易次数占总交易次数比" bigint,
    "指定国内池到过渡地址的交易金额" double precision,
    "过渡地址到国外交易所的交易金额" double precision,
    "上链时间" timestamp with time zone,
    "过渡地址最新交易时间" timestamp with time zone,
    "国内交易所到过渡地址的首次交易时间" timestamp with time zone,
    "过渡地址到国外交易所的最新交易时间" timestamp with time zone,
    "国内所有交易所到过渡地址的交易总金额" double precision,
    "国内所有交易所到过渡地址的交易总次数" numeric,
    "与国内所有交易所最早交易时间" timestamp with time zone,
    "是否疑似国外" text,
    "与国内交易所的最新交易hash" text,
    "国外交易所的个数" bigint,
    "与国外交易所的交易数" bigint,
    "是否已被调证" boolean
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_investigated_cn OWNER TO oushu;

--
-- Name: statics_final_v1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE statics_final_v1 (
    to1 text,
    exchange_domestic text,
    exchange_overseas text,
    date_count bigint,
    domestic_trans_count bigint,
    overseas_trans_count bigint,
    trans_count_all bigint,
    "?column?" bigint,
    domestic_trans_amount double precision,
    overseas_trans_amount double precision,
    boarding_time text,
    lastest_time text,
    domestic_min_ts timestamp with time zone,
    overseas_max_ts timestamp with time zone,
    all_domestic_trans_amount double precision,
    all_domestic_trans_count numeric,
    all_domestic_min_ts bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_v1 OWNER TO gpadmin;

--
-- Name: statics_final_v4; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE statics_final_v4 (
    "境外交易所过渡账户地址" text,
    "国内交易所" text,
    "国外交易所" text,
    "给境外指定交易所转币天数" bigint,
    "接受国内指定交易所转币天数" bigint,
    "指定国内交易所到1的交易次数 A" bigint,
    "过渡地址给境外指定交易所转币次数" bigint,
    "总交易次数" bigint,
    "与交易所交易次数占总交易次数比" bigint,
    "指定国内池到过渡地址的交易金额" double precision,
    "过渡地址到国外交易所的交易金额" double precision,
    "上链时间" text,
    "过渡地址最新交易时间" text,
    "国内交易所到过渡地址的首次交易时间" timestamp with time zone,
    "过渡地址到国外交易所的最新交易时间" timestamp with time zone,
    "国内所有交易所到过渡地址的交易总金额" double precision,
    "国内所有交易所到过渡地址的交易总次数" numeric,
    "与国内所有交易所最早交易时间" timestamp with time zone
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_v4 OWNER TO gpadmin;

--
-- Name: statics_final_with_hash; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_with_hash (
    "境外交易所过渡账户地址" text,
    "国内交易所" text,
    "国外交易所" text,
    "给境外指定交易所转币天数" bigint,
    "接受国内指定交易所转币天数" bigint,
    "指定国内交易所到1的交易次数 A" bigint,
    "过渡地址给境外指定交易所转币次数" bigint,
    "总交易次数" bigint,
    "与交易所交易次数占总交易次数比" bigint,
    "指定国内池到过渡地址的交易金额" double precision,
    "过渡地址到国外交易所的交易金额" double precision,
    "上链时间" timestamp with time zone,
    "过渡地址最新交易时间" timestamp with time zone,
    "国内交易所到过渡地址的首次交易时间" timestamp with time zone,
    "过渡地址到国外交易所的最新交易时间" timestamp with time zone,
    "国内所有交易所到过渡地址的交易总金额" double precision,
    "国内所有交易所到过渡地址的交易总次数" numeric,
    "与国内所有交易所最早交易时间" timestamp with time zone,
    "是否疑似国外" text,
    "与国内交易所的最新交易hash" text,
    "国外交易所的个数" bigint,
    "与国外交易所的交易数" bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_with_hash OWNER TO oushu;

--
-- Name: statics_final_with_hash_en; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_final_with_hash_en (
    to1 text,
    exchange_domestic text,
    exchange_overseas text,
    overseas_date_count bigint,
    domestic_date_count bigint,
    domestic_trans_count bigint,
    overseas_trans_count bigint,
    trans_count_all bigint,
    rate bigint,
    domestic_trans_amount double precision,
    overseas_trans_amount double precision,
    boarding_time timestamp with time zone,
    lastest_time timestamp with time zone,
    domestic_min_ts timestamp with time zone,
    overseas_max_ts timestamp with time zone,
    all_domestic_trans_amount double precision,
    all_domestic_trans_count numeric,
    to_timestamp timestamp with time zone,
    is_oversea text,
    transactionhash text,
    cnt_tag bigint,
    cnt_tx bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_final_with_hash_en OWNER TO oushu;

--
-- Name: statics_hash_dup; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_hash_dup (
    to1 text,
    exchange_domestic text,
    exchange_overseas text,
    overseas_date_count bigint,
    domestic_date_count bigint,
    domestic_trans_count bigint,
    overseas_trans_count bigint,
    trans_count_all bigint,
    rate bigint,
    domestic_trans_amount double precision,
    overseas_trans_amount double precision,
    boarding_time timestamp with time zone,
    lastest_time timestamp with time zone,
    domestic_min_ts timestamp with time zone,
    overseas_max_ts timestamp with time zone,
    all_domestic_trans_amount double precision,
    all_domestic_trans_count numeric,
    to_timestamp timestamp with time zone,
    is_oversea text,
    transactionhash text,
    cnt_tag bigint,
    cnt_tx bigint,
    cnt bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_hash_dup OWNER TO oushu;

--
-- Name: statics_middle; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_middle (
    to1 text,
    exchange_domestic text,
    exchange_overseas text,
    overseas_date_count bigint,
    domestic_date_count bigint,
    domestic_trans_count bigint,
    domestic_trans_amount double precision,
    domestic_min_ts timestamp with time zone,
    overseas_trans_count bigint,
    overseas_trans_amount double precision,
    overseas_max_ts timestamp with time zone,
    all_domestic_trans_count numeric,
    all_domestic_trans_amount double precision,
    all_domestic_min_ts bigint
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_middle OWNER TO oushu;

--
-- Name: statics_overall; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE statics_overall (
    to1 text,
    trans_count_all bigint,
    boarding_time timestamp with time zone,
    lastest_time timestamp with time zone
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.statics_overall OWNER TO oushu;

--
-- Name: suspect_pool_all; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE suspect_pool_all (
    address text,
    cnt integer,
    cnt_tx integer,
    sum_value numeric(38,20),
    min_ts timestamp without time zone,
    max_ts timestamp without time zone,
    is_suspect text,
    exchange_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.suspect_pool_all OWNER TO oushu;

--
-- Name: suspect_pool_all_v2; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE suspect_pool_all_v2 (
    address text,
    cnt integer,
    cnt_tx integer,
    sum_value numeric(38,20),
    min_ts timestamp without time zone,
    max_ts timestamp without time zone,
    is_suspect text,
    exchange_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.suspect_pool_all_v2 OWNER TO oushu;

--
-- Name: t; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t (
    id character varying(60),
    blocknumber character varying(100),
    timestamp1 character varying(100),
    transactionhash character varying(100),
    from1 character varying(100),
    to1 character varying(100),
    creates character varying(100),
    value1 character varying(100),
    gaslimit character varying(100),
    gasprice character varying(100),
    gasused character varying(100),
    status character varying(100),
    filename character varying(100),
    rksj character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t OWNER TO gpadmin;

--
-- Name: t1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t1 (
    from1 character varying(100),
    to1 character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t1 OWNER TO gpadmin;

--
-- Name: t2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t2 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t2 OWNER TO gpadmin;

--
-- Name: t2_res; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t2_res (
    to1 text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t2_res OWNER TO gpadmin;

--
-- Name: t_binance; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_binance (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_binance OWNER TO gpadmin;

--
-- Name: t_binance2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_binance2 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_binance2 OWNER TO gpadmin;

--
-- Name: t_binance3; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_binance3 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_binance3 OWNER TO gpadmin;

--
-- Name: t_binance4; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_binance4 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_binance4 OWNER TO gpadmin;

--
-- Name: t_bithumb1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_bithumb1 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_bithumb1 OWNER TO gpadmin;

--
-- Name: t_bithumb3; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_bithumb3 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_bithumb3 OWNER TO gpadmin;

--
-- Name: t_bithumbcontract1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_bithumbcontract1 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_bithumbcontract1 OWNER TO gpadmin;

--
-- Name: t_eth_block_detail; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_eth_block_detail (
    id character varying(255) NOT NULL,
    hash character varying(255),
    blockheight character varying(255),
    parenthash character varying(255),
    sha3uncles character varying(255),
    transactionsroot character varying(255),
    stateroot character varying(255),
    logsbloom text,
    difficulty character varying(255),
    totaldifficulty character varying(255),
    gaslimit character varying(255),
    gasused character varying(255),
    extradata character varying(255),
    "timestamp" character varying(255),
    blocksize character varying(255),
    miner character varying(255),
    nonce character varying(255),
    staticreward character varying(255),
    blockreward character varying(255),
    totalunclesreward character varying(255),
    totalfees character varying(255),
    transactioncount character varying(255),
    internaltransactioncount character varying(255),
    rksj character varying(255),
    uncles text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_detail OWNER TO oushu;

--
-- Name: t_eth_block_detail_ws; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_eth_block_detail_ws (
    hash text,
    blockheight bigint,
    parenthash text,
    sha3uncles text,
    transactionsroot text,
    stateroot text,
    logsbloom text,
    difficulty text,
    totaldifficulty text,
    gaslimit text,
    gasused text,
    extradata text,
    "timestamp" text,
    blocksize text,
    miner text,
    nonce text,
    staticreward text,
    blockreward text,
    totalunclesreward text,
    totalfees text,
    transactioncount text,
    internaltransactioncount text,
    uncles text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_detail_ws OWNER TO gpadmin;

--
-- Name: t_eth_block_internaltran; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_eth_block_internaltran (
    id character varying(255) NOT NULL,
    blockhash character varying(255),
    blocknumber character varying(255),
    type character varying(255),
    internaltransactionto character varying(255),
    internaltransactionfrom character varying(255),
    value character varying(255),
    transactionhash character varying(255),
    "timestamp" character varying(255),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_internaltran OWNER TO oushu;

--
-- Name: t_eth_block_internaltran_ws; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_eth_block_internaltran_ws (
    blockhash text,
    blocknumber text,
    type text,
    internaltransactionto text,
    internaltransactionfrom text,
    value text,
    transactionhash text,
    "timestamp" text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_internaltran_ws OWNER TO gpadmin;

--
-- Name: t_eth_block_transactions; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_eth_block_transactions (
    id character varying(255) NOT NULL,
    hash character varying(255),
    blockhash character varying(255),
    blocknumber character varying(255),
    transactionto character varying(255),
    transactionfrom character varying(255),
    value character varying(255),
    nonce character varying(255),
    gasprice character varying(255),
    gaslimit character varying(255),
    gasused character varying(255),
    data text,
    transactionindex character varying(255),
    success character varying(255),
    state character varying(255),
    "timestamp" character varying(255),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_transactions OWNER TO oushu;

--
-- Name: t_eth_block_transactions_ws; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_eth_block_transactions_ws (
    hash text,
    blockhash text,
    blocknumber text,
    transactionto text,
    transactionfrom text,
    value text,
    nonce text,
    gasprice text,
    gaslimit text,
    gasused text,
    data text,
    transactionindex text,
    success text,
    state text,
    "timestamp" text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_transactions_ws OWNER TO gpadmin;

--
-- Name: t_eth_block_transfer; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_eth_block_transfer (
    id character varying(255) NOT NULL,
    logindex character varying(255),
    tokenhash character varying(255),
    transferto character varying(255),
    transferfrom character varying(255),
    value character varying(255),
    decimals character varying(255),
    blockhash character varying(255),
    transactionhash character varying(255),
    blocknumber character varying(255),
    idxfrom character varying(255),
    idxto character varying(255),
    accountidxfrom character varying(255),
    accountidxto character varying(255),
    "timestamp" character varying(255),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_transfer OWNER TO oushu;

--
-- Name: t_eth_block_transfer_ws; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_eth_block_transfer_ws (
    logindex text,
    tokenhash text,
    transferto text,
    transferfrom text,
    value text,
    decimals text,
    blockhash text,
    transactionhash text,
    blocknumber text,
    idxfrom text,
    idxto text,
    accountidxfrom text,
    accountidxto text,
    "timestamp" text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_eth_block_transfer_ws OWNER TO gpadmin;

--
-- Name: t_ethereum_block_bmr; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_ethereum_block_bmr (
    blocknumber character varying(100),
    "timestamp" character varying(100),
    miner character varying(100),
    reward character varying(100),
    rksj character varying(100),
    wjjmc character varying(100),
    id character varying(100) NOT NULL
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_block_bmr OWNER TO oushu;

--
-- Name: t_ethereum_block_qmr; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_ethereum_block_qmr (
    id character varying(100) NOT NULL,
    blocknumber character varying(100),
    "timestamp" character varying(100),
    size1 character varying(100),
    difficulty character varying(100),
    transactioncount character varying(100),
    mineraddress character varying(100),
    minerextra character varying(100),
    gaslimit character varying(100),
    gasused character varying(100),
    mingasprice character varying(100),
    maxgasprice character varying(100),
    avggasprice character varying(100),
    txfee character varying(100),
    rksj character varying(100),
    wjjmc character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_block_qmr OWNER TO oushu;

--
-- Name: t_ethereum_ct_info_created; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_ethereum_ct_info_created (
    id character varying(60),
    address character varying(100),
    createdblocknumber character varying(100),
    createdtimestamp character varying(100),
    createdtransactionhash character varying(100),
    creator character varying(100),
    creatoriscontract character varying(100),
    createvalue character varying(100),
    creationcode bytea,
    contractcode bytea,
    filename character varying(100),
    rksj character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_ct_info_created OWNER TO gpadmin;

--
-- Name: t_ethereum_ct_info_decreated; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_ethereum_ct_info_decreated (
    id character varying(60),
    address character varying(100),
    decreatedblocknumber character varying(100),
    decreatedtimestamp character varying(100),
    decreatedtransactionhash character varying(100),
    refunder character varying(100),
    refunderiscontract character varying(100),
    refundvalue character varying(100),
    filename character varying(100),
    rksj character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_ct_info_decreated OWNER TO gpadmin;

--
-- Name: t_ethereum_erct; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_ethereum_erct (
    id character varying(100) NOT NULL,
    blocknumber character varying(100),
    "timestamp" character varying(100),
    transactionhash character varying(500),
    tokenaddress character varying(100),
    from1 character varying(100),
    to1 character varying(100),
    fromiscontract character varying(100),
    toiscontract character varying(100),
    tokenid character varying(100),
    rksj character varying(100),
    wjjmc character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_erct OWNER TO oushu;

--
-- Name: t_ethereum_iet; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_ethereum_iet (
    id character varying(100) NOT NULL,
    blocknumber character varying(100),
    "timestamp" character varying(100),
    transactionhash character varying(500),
    tokenaddress character varying(100),
    from1 character varying(100),
    to1 character varying(100),
    fromiscontract character varying(100),
    toiscontract character varying(100),
    value character varying(100),
    rksj character varying(100),
    wjjmc character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_iet OWNER TO oushu;

--
-- Name: t_ethereum_nm_ta; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_ethereum_nm_ta (
    id character varying(60) NOT NULL,
    blocknumber character varying(100),
    timestamp1 character varying(100),
    transactionhash character varying(100),
    from1 character varying(100),
    to1 character varying(100),
    creates character varying(100),
    value1 character varying(100),
    gaslimit character varying(100),
    gasprice character varying(100),
    gasused character varying(100),
    status character varying(100),
    filename character varying(100),
    rksj character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_nm_ta OWNER TO oushu;

--
-- Name: t_ethereum_scad; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_ethereum_scad (
    id character varying(40) NOT NULL,
    address character varying(80),
    "timestamp" character varying(40),
    createvalue character varying(40),
    createdblocknumber character varying(40),
    createdtransactionhash character varying(80),
    creator character varying(80),
    code text,
    creationcode text,
    contractcode text,
    filename character varying(40),
    createtime character varying(20)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_ethereum_scad OWNER TO oushu;

--
-- Name: t_huobi2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_huobi2 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_huobi2 OWNER TO gpadmin;

--
-- Name: t_jz_eth_acount_dbjy; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_eth_acount_dbjy (
    id character varying(255) NOT NULL,
    tx_hash character varying(4000),
    block_height character varying(4000),
    created_ts character varying(4000),
    time_in_sec character varying(4000),
    sender_hash character varying(4000),
    receiver_hash character varying(4000),
    amount character varying(4000),
    token_hash character varying(4000),
    token_name character varying(4000),
    token_decimal character varying(4000),
    unit_name character varying(4000),
    token_found character varying(4000),
    sender_name character varying(4000),
    receiver_name character varying(4000),
    sender_type character varying(4000),
    receiver_type character varying(4000),
    token_url character varying(4000),
    tx_type character varying(4000),
    token_icon_url character varying(4000),
    glaccount_hash character varying(4000),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_jz_eth_acount_dbjy OWNER TO oushu;

--
-- Name: t_jz_eth_block_detail; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_eth_block_detail (
    id character varying(255) NOT NULL,
    block_basic_reward character varying(4000),
    block_hash character varying(4000),
    block_height character varying(4000),
    block_reward character varying(4000),
    block_reward_percentage character varying(4000),
    block_reward_rmb character varying(4000),
    block_reward_usd character varying(4000),
    block_size character varying(4000),
    block_time_in_sec character varying(4000),
    created_ts character varying(4000),
    difficulty character varying(4000),
    extra_data character varying(4000),
    extra_data_decoded character varying(4000),
    fee character varying(4000),
    fee_rmb character varying(4000),
    fee_usd character varying(4000),
    gas_avg_price character varying(4000),
    gas_limit character varying(4000),
    gas_used character varying(4000),
    gas_used_percentage character varying(4000),
    miner_hash character varying(4000),
    miner_icon_url character varying(4000),
    miner_name character varying(4000),
    nonce character varying(4000),
    parent_hash character varying(4000),
    time_in_sec character varying(4000),
    total_difficulty character varying(4000),
    total_internal_tx character varying(4000),
    total_tx character varying(4000),
    total_uncle character varying(4000),
    uncle_ref_reward character varying(4000),
    rksj character varying(255) NOT NULL
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_jz_eth_block_detail OWNER TO oushu;

--
-- Name: t_jz_eth_jy; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_eth_jy (
    id character varying(255) NOT NULL,
    tx_hash character varying(255),
    sender_hash character varying(255),
    receiver_hash character varying(255),
    amount character varying(255),
    fee character varying(255),
    gas_used character varying(255),
    gas_price character varying(255),
    tx_type character varying(255),
    created_ts character varying(255),
    status character varying(255),
    sender_type character varying(255),
    receiver_type character varying(255),
    internal_tx text,
    block_height character varying(255),
    rksj character varying(255)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_jz_eth_jy OWNER TO oushu;

--
-- Name: t_jz_eth_skxx_detail; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_jz_eth_skxx_detail (
    id character varying(255) NOT NULL,
    uncle_hash character varying(4000),
    uncle_height character varying(4000),
    miner_hash character varying(4000),
    uncle_reward character varying(4000),
    extra_data character varying(4000),
    created_ts character varying(4000),
    miner_name character varying(4000),
    miner_icon_url character varying(4000),
    extra_data_decoded character varying(4000),
    rksj character varying(255),
    block_height character varying(4000)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_jz_eth_skxx_detail OWNER TO oushu;

--
-- Name: t_okex1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_okex1 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_okex1 OWNER TO gpadmin;

--
-- Name: t_okex2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_okex2 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_okex2 OWNER TO gpadmin;

--
-- Name: t_okex3; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_okex3 (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_okex3 OWNER TO gpadmin;

--
-- Name: t_tag; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_tag (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_tag OWNER TO gpadmin;

--
-- Name: t_tag_erc20; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE t_tag_erc20 (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_tag_erc20 OWNER TO oushu;

--
-- Name: t_tmp; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_tmp (
    from1 text,
    to1 text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_tmp OWNER TO gpadmin;

--
-- Name: t_to1; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE t_to1 (
    to1 text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.t_to1 OWNER TO gpadmin;

--
-- Name: tag_all; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE tag_all (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.tag_all OWNER TO gpadmin;

--
-- Name: tag_all_v2; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE tag_all_v2 (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.tag_all_v2 OWNER TO gpadmin;

--
-- Name: tag_all_v3; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE tag_all_v3 (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.tag_all_v3 OWNER TO gpadmin;

--
-- Name: tag_all_v4; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE tag_all_v4 (
    address text,
    tag_name text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.tag_all_v4 OWNER TO oushu;

--
-- Name: tb1; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE tb1 (
    id integer,
    name text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.tb1 OWNER TO oushu;

--
-- Name: trans_domestic; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_domestic (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text,
    exchange_domestic text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.trans_domestic OWNER TO oushu;

--
-- Name: trans_overseas; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE trans_overseas (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text,
    exchange_overseas text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.trans_overseas OWNER TO oushu;

--
-- Name: trans_to; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE trans_to (
    to1 character varying(100),
    tx_date text,
    transactionhash character varying(500),
    value character varying(100),
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.trans_to OWNER TO gpadmin;

--
-- Name: transa; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE transa (
    hash text,
    blockhash text,
    blocknumber text,
    transactionto text,
    transactionfrom text,
    value text,
    nonce text,
    gasprice text,
    gaslimit text,
    gasused text,
    data text,
    transactionindex text,
    success text,
    state text,
    "timestamp" text,
    rksj text,
    amount text,
    fee text,
    tx_type text,
    created_ts text,
    status text,
    sender_type text,
    receiver_type text,
    creates text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transa OWNER TO gpadmin;

--
-- Name: transa_ao; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE transa_ao (
    hash text,
    blockhash text,
    blocknumber text,
    transactionto text,
    transactionfrom text,
    value text,
    nonce text,
    gasprice text,
    gaslimit text,
    gasused text,
    data text,
    transactionindex text,
    success text,
    state text,
    "timestamp" text,
    rksj text,
    amount text,
    fee text,
    tx_type text,
    created_ts text,
    status text,
    sender_type text,
    receiver_type text,
    creates text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transa_ao OWNER TO oushu;

--
-- Name: transa_ao_his; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE transa_ao_his (
    hash text,
    blockhash text,
    blocknumber text,
    transactionto text,
    transactionfrom text,
    value text,
    nonce text,
    gasprice text,
    gaslimit text,
    gasused text,
    data text,
    transactionindex text,
    success text,
    state text,
    "timestamp" text,
    rksj text,
    amount text,
    fee text,
    tx_type text,
    created_ts text,
    status text,
    sender_type text,
    receiver_type text,
    creates text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transa_ao_his OWNER TO oushu;

--
-- Name: transaction_domestic; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE transaction_domestic (
    to1 text,
    exchange_name text,
    transactionhash text,
    "timestamp" text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transaction_domestic OWNER TO oushu;

--
-- Name: transaction_transit; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE transaction_transit (
    to1 text,
    from1 text,
    transactionhash text,
    "timestamp" text
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transaction_transit OWNER TO oushu;

--
-- Name: transit_overseas; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE transit_overseas (
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transit_overseas OWNER TO oushu;

--
-- Name: transres; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE transres (
    blocknumber character varying(100),
    transactioncount character varying(100),
    cnt bigint
)
WITH (appendonly=true, orientation=orc, compresstype=lz4, dicthreshold=0.8) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.transres OWNER TO gpadmin;

--
-- Name: ttt; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE ttt (
    a integer
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.ttt OWNER TO oushu;

--
-- Name: upbit_suspects; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE upbit_suspects (
    to1 character varying(100),
    date_count bigint,
    amount numeric,
    is_contract character varying(100)
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.upbit_suspects OWNER TO gpadmin;

--
-- Name: usdt_bithumb_suspects; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_bithumb_suspects (
    to1 text,
    date_count bigint,
    "?column?" double precision,
    is_contract text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.usdt_bithumb_suspects OWNER TO oushu;

--
-- Name: usdt_huobi_bithumb_suspects; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_huobi_bithumb_suspects (
    to1 text,
    date_count bigint,
    amount double precision,
    is_contract text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.usdt_huobi_bithumb_suspects OWNER TO oushu;

--
-- Name: usdt_okex_upbit_suspects; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE usdt_okex_upbit_suspects (
    to1 text,
    date_count bigint,
    "?column?" double precision,
    is_contract text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.usdt_okex_upbit_suspects OWNER TO oushu;

--
-- Name: wuhao; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE wuhao (
    txid text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.wuhao OWNER TO gpadmin;

--
-- Name: zeng_address_tag; Type: TABLE; Schema: ytf; Owner: gpadmin; Tablespace: 
--

CREATE TABLE zeng_address_tag (
    address text,
    tag_name text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.zeng_address_tag OWNER TO gpadmin;

--
-- Name: zeng_board_address; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE zeng_board_address (
    address text,
    tag_name text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.zeng_board_address OWNER TO oushu;

--
-- Name: zeng_board_transaction; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE zeng_board_transaction (
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.zeng_board_transaction OWNER TO oushu;

--
-- Name: zeng_result; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE zeng_result (
    from1_tag text,
    blocknumber bigint,
    "timestamp" text,
    transactionhash text,
    from1 text,
    to1 text,
    creates text,
    value text,
    gaslimit text,
    gasprice text,
    gasused text,
    callingfunction text,
    iserror text,
    tag_name text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.zeng_result OWNER TO oushu;

--
-- Name: zeng_result_final; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE zeng_result_final (
    from1_tag text,
    to1_tag text,
    transactionhash text,
    from1 text,
    to1 text,
    blocknumber bigint,
    ts timestamp with time zone,
    amount double precision,
    uid text,
    way text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.zeng_result_final OWNER TO oushu;

--
-- Name: zeng_withdraw_address; Type: TABLE; Schema: ytf; Owner: oushu; Tablespace: 
--

CREATE TABLE zeng_withdraw_address (
    address text
)
WITH (appendonly=true) DISTRIBUTED RANDOMLY;


ALTER TABLE ytf.zeng_withdraw_address OWNER TO oushu;

SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: oushu
--

ALTER TABLE trc20_token ALTER COLUMN id SET DEFAULT nextval('trc20_token_id_seq'::regclass);


--
-- Name: public; Type: ACL; Schema: -; Owner: gpadmin
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM gpadmin;
GRANT ALL ON SCHEMA public TO gpadmin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: ytf; Type: ACL; Schema: -; Owner: gpadmin
--

REVOKE ALL ON SCHEMA ytf FROM PUBLIC;
REVOKE ALL ON SCHEMA ytf FROM gpadmin;
GRANT ALL ON SCHEMA ytf TO gpadmin;
GRANT ALL ON SCHEMA ytf TO test;


--
-- Greenplum Database database dump complete
--

