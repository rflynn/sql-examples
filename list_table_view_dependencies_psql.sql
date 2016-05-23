
-- list tables and views and all the views/materialized views that depend on them, recursively
-- tested on psql 9.4

/*
drop table if exists accounts;
drop table if exists node;
drop table if exists node_relations;
drop table if exists transactions;
drop schema if exists lazy cascade;
*/

create table t (id int);
drop view if exists v1 cascade;
drop view if exists v2 cascade;
drop view if exists v3 cascade;
create view v1 as select * from t;
create view v2 as select * from v1;
create view v3 as select * from v1;
drop materialized view if exists m1 cascade;
drop materialized view if exists m2 cascade;
drop materialized view if exists m3 cascade;
create materialized view m1 as select * from t;
create materialized view m2 as select * from m1;
create materialized view m3 as select * from m2;

WITH RECURSIVE
schemas AS (
    SELECT oid FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema'
),
tvm AS (
    SELECT oid, oid::regclass::text as txt, relkind
    FROM  pg_class
    WHERE relkind IN ('r', 'v', 'm')
    AND relpersistence = 'p' -- permanent
    AND relnamespace IN (SELECT oid FROM schemas)
),
dep AS (
    SELECT tvm.oid as tvmoid,
           tvm.oid::regclass::text as ttxt,
           tvm.relkind,
           r.ev_class::REGCLASS as revclass
    FROM tvm
    LEFT JOIN pg_depend d ON d.refobjid = tvm.oid::REGCLASS
    LEFT JOIN pg_rewrite r ON r.oid = d.objid
    WHERE r.ev_class IS NULL or r.ev_class != tvm.oid
),
depagg AS (
    select ttxt, relkind, array_remove(array_agg(revclass::text), NULL) as adep
    from dep
    group by ttxt, relkind
),
recurse AS (
    -- XXX: this algorithm is flawed, because i can't figure out how to detect
    -- interdependencies between rows in a single "pass"... so instead, just add everything
    -- and as a hack, filter out all but the last appearance of each entity. ugh
    SELECT ttxt::text, 1 as pass, relkind, adep
        FROM depagg
        WHERE adep = ARRAY[]::text[]
    UNION ALL
    SELECT d.ttxt, r.pass + 1 as pass, d.relkind, d.adep
        FROM depagg d
        JOIN recurse r ON 1=1
        WHERE r.ttxt = ANY(d.adep) -- next level of the tree, mentioned in a predecessor
),
depnum AS (
    SELECT ROW_NUMBER() OVER () as rown, ttxt, pass, relkind, adep
    FROM recurse
),
filterdupes AS (
    SELECT rown, ttxt, pass, relkind, adep
    FROM depnum
    GROUP BY rown, ttxt, pass, relkind, adep
    HAVING rown in (select max(rown) from depnum group by ttxt)
    ORDER BY rown
)
SELECT ttxt, pass, relkind, adep
FROM filterdupes;

