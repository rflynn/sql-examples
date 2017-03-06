with recursive
federal_holidays (date, descr) as (
    values
        ('2016-09-05'::date, 'Labor Day'       ),
        ('2016-10-10'::date, 'Columbus Day'    ),
        ('2016-11-11'::date, 'Veterans Day'    ),
        ('2016-11-24'::date, 'Thanksgiving Day'),
        ('2016-12-25'::date, 'Christmas Day'   )
        -- ...
),
every_day as (
    -- list every date the app will consider
    select '2016-08-24'::date as d
    union all
    select (d + interval '1 day')::date from every_day where d < '2018-01-01'::date
),
dows as (
    -- calculate metadata about every_day
    select
        d,
        extract(dow from d) as dow,
        extract(dow from d) in (0, 6) as is_weekend,
        exists(select 1 from federal_holidays where date=d) as is_holiday
    from every_day
),
schedulable as (
    -- for each day, figure out the next schedulable day
    select
        dows.d,
        (select min(s.d) from dows s where s.d >= dows.d and not s.is_weekend and not s.is_holiday) as next_business_day
    from dows
),
some_naive_monthly_schedule (d, n) as (
    -- given a starting date, calculate subsequent naive dates
    -- use the 31st of the month as a test as it doesn't exist in many months and gives the least intuitive results
    -- NOTE: use (starting_date + n months) instead of (last_date + 1 month),
    -- as months with fewer days like feb will trim the 31st down to 28th for all subsequent months
    select '2016-10-31'::date, 1
    union all
    select ('2016-10-31'::date + (interval '1 month' * n))::date, n + 1 from some_naive_monthly_schedule where n < 12
),
monthly_schedule_adjusted as (
    -- translate each naive day to the next scheduable day
    select
        snms.d,
        s.next_business_day
    from some_naive_monthly_schedule snms
    left join schedulable s on s.d = snms.d
)
select * from monthly_schedule_adjusted;
