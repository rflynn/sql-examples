with recursive
key_days (year, jan1, feb29) as (
    select
        1600,
        '1600-01-01'::date,
        '1600-03-01'::date - interval '1 day'
    union all
    select
        year + 1,
        (jan1 + interval '1 year')::date,
        jan1 + interval '1 year' + interval '2 months' - interval '1 day'
    from key_days where year <= 2018
),
dows as (
    -- calculate metadata about every_day
    select
        year,
        extract(dow from jan1) as jan1_dow,
        extract(day from feb29) = 29 as is_leapyear
    from key_days
    order by year
),
year_config as (
    select
        jan1_dow,
        is_leapyear,
        array_agg(year order by year)
    from dows
    group by jan1_dow, is_leapyear
    order by jan1_dow, is_leapyear
)
select * from year_config;
