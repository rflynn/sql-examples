
-- list tables and views and all the views/materialized views that depend on them, recursively
-- tested on psql 9.4

WITH RECURSIVE
tables AS (
    SELECT schemaname, tablename FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema') -- skip the built-ins
    AND schemaname NOT LIKE 'pg_%'
),
vlist AS (
    SELECT
        c.oid::REGCLASS AS view_name,
        c.relkind::text AS relkind,
        t.tablename AS tbl_name,
        t.schemaname AS schema
      FROM pg_class c, tables t
     WHERE c.relname = t.tablename
     UNION ALL
    SELECT
        DISTINCT r.ev_class::REGCLASS AS view_name,
        c.relkind::text AS relkind,
        tbl_name,
        schema
      FROM pg_depend d
      JOIN pg_rewrite r ON (r.oid = d.objid)
      JOIN vlist ON (vlist.view_name = d.refobjid)
      JOIN pg_class c ON c.oid = r.ev_class
     WHERE d.refobjsubid != 0
)
SELECT schema::text, tbl_name::text, view_name::text, relkind::text
FROM vlist
ORDER BY schema, tbl_name, view_name;

