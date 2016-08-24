with recursive
intervals as (
    select date_trunc('month', now() + interval '1 month')::date as mo
    union all
    select (mo + interval '1 month')::date from intervals where mo < '2018-01-01'::date
)
select * from intervals;
