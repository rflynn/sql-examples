with recursive
key_days (year, jan1, feb29) as (
    select
        1600,
        '1600-01-01'::date,
        '1600-03-01'::date - interval '1 day'
    union all
    select
        year  + 1,
        (jan1 + interval '1 year')::date,
        jan1 + interval '1 year' + interval '2 months' - interval '1 day'
    from key_days where year <= 2018
),
dows as (
    -- calculate metadata about every_day
    select
        year,
        jan1,
        extract(dow from jan1) as jan1_dow,
        extract(day from feb29) as feb29
    from key_days
    order by year
),
year_config as (
    select
        jan1_dow,
        feb29,
        array_agg(year order by year)
    from dows
    group by jan1_dow, feb29
    order by jan1_dow, feb29
)
select * from year_config;
