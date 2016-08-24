with recursive
federal_holidays (date, descr) as (
    values
        ('2016-09-05'::date, 'Labor Day'       ),
        ('2016-10-10'::date, 'Columbus Day'    ),
        ('2016-11-11'::date, 'Veterans Day'    ),
        ('2016-11-24'::date, 'Thanksgiving Day'),
        ('2016-12-26'::date, 'Christmas Day'   )
        -- ...
),
days as (
    select '2016-08-24'::date as d
    union all
    select (d + interval '1 day')::date from days where d < now() + interval '1 month'
),
dows as (
    select
        d,
        extract(dow from d) as dow,
        extract(dow from d) in (0, 6) as is_weekend,
        exists(select 1 from federal_holidays where date=d) as is_holiday
    from days
),
unschedulable as (
    select d from dows where is_weekend or is_holiday
),
schedulable as (
    select
        dows.d,
        dows.dow,
        dows.is_weekend,
        dows.is_holiday,
        (select max(s.d) from dows s where s.d <= dows.d and not s.is_weekend and not s.is_holiday) as prev_schedulable,
        (select min(s.d) from dows s where s.d >= dows.d and not s.is_weekend and not s.is_holiday) as next_schedulable
    from dows
)
select * from schedulable;
