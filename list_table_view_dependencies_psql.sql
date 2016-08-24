
-- list tables and views and all the views/materialized views that depend on them, recursively
-- tested on psql 9.4

/*
drop table if exists accounts;
drop table if exists node;
drop table if exists node_relations;
drop table if exists transactions;
drop schema if exists lazy cascade;
*/

/*
drop schema if exists test_list_deps cascade;
create schema test_list_deps;

-- test data of interdependent tables, views and materialized views
create table test_list_deps.t (id int);
drop view if exists v1 cascade;
drop view if exists v2 cascade;
drop view if exists v3 cascade;
drop view if exists test_list_deps.v1 cascade;
drop view if exists test_list_deps.v2 cascade;
drop view if exists test_list_deps.v3 cascade;
create view test_list_deps.v1 as select * from test_list_deps.t;
create view test_list_deps.v2 as select * from test_list_deps.v1;
create view test_list_deps.v3 as select * from test_list_deps.v1;
drop materialized view if exists m1 cascade;
drop materialized view if exists m2 cascade;
drop materialized view if exists m3 cascade;
drop materialized view if exists test_list_deps.m1 cascade;
drop materialized view if exists test_list_deps.m2 cascade;
drop materialized view if exists test_list_deps.m3 cascade;
create materialized view test_list_deps.m1 as select * from test_list_deps.t;
create materialized view test_list_deps.m2 as select * from test_list_deps.m1;
create materialized view test_list_deps.m3 as select * from test_list_deps.m2;
*/

WITH RECURSIVE
schemas AS (
    SELECT nspname, oid
    FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%' -- ignore built-in stuff
    AND nspname != 'information_schema'
),
tvm AS (
    SELECT s.nspname as schema, c.oid, c.oid::regclass::text as txt, c.relkind
    FROM  pg_class c
    JOIN schemas s on s.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'v', 'm')
    AND c.relpersistence = 'p' -- permanent
),
dep AS (
    SELECT tvm.oid as tvmoid,
           tvm.oid::regclass::text as ttxt,
           tvm.relkind,
           r.ev_class::REGCLASS as revclass,
           tvm.schema as schema
    FROM tvm
    LEFT JOIN pg_depend d ON d.refobjid = tvm.oid::REGCLASS
    LEFT JOIN pg_rewrite r ON r.oid = d.objid
    WHERE r.ev_class IS NULL or r.ev_class != tvm.oid
),
depagg AS (
    select dep.schema,
           ttxt,
           relkind,
           array_remove(array_agg(distinct revclass::text), NULL) as adep
    from dep
    group by schema, ttxt, relkind
),
recurse AS (
    -- walk the dependency tree from the leaf nodes back to the root-ish tables
    -- on each pass, include the parents of the previous pass
    -- XXX: this algorithm is flawed, because i can't figure out how to detect
    -- interdependencies between rows in a single "pass"... so instead, just add everything
    -- and as a hack, filter out all but the last appearance of each entity. ugh
    SELECT schema, ttxt::text, 1 as pass, relkind, adep
        FROM depagg
        WHERE adep = ARRAY[]::text[] -- leaf nodes w/ no dependencies
    UNION ALL
    SELECT d.schema, d.ttxt, r.pass + 1 as pass, d.relkind, d.adep
        FROM depagg d
        JOIN recurse r ON 1=1
        WHERE r.ttxt = ANY(d.adep) -- parent level of previous pass, one step up the tree
),
depnum AS (
    SELECT ROW_NUMBER() OVER () as rown, schema, ttxt, pass, relkind, adep
    FROM recurse
),
filterdupes AS (
    SELECT rown, d.schema, ttxt, pass, relkind, adep
    FROM depnum d
    GROUP BY rown, schema, ttxt, pass, relkind, adep
    HAVING rown in (select max(rown) from depnum group by ttxt)
    ORDER BY rown
)
SELECT schema, ttxt, pass, relkind, adep
FROM filterdupes;

