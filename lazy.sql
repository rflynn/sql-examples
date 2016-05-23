
-- ref: https://hashrocket.com/blog/posts/materialized-view-strategies-using-postgresql


drop schema if exists test_lazy cascade;
create schema test_lazy;


drop table if exists test_lazy.accounts cascade;
create table test_lazy.accounts(
  name varchar primary key
);

insert into test_lazy.accounts (name)
          select 'foo'
union all select 'bar'
union all select 'baz'
;

drop table if exists test_lazy.transactions;
create table test_lazy.transactions(
  id serial primary key,
  name varchar not null references test_lazy.accounts
    on update cascade
    on delete cascade,
  amount numeric(9,2) not null,
  post_time timestamptz not null
);

create index on test_lazy.transactions (name);
create index on test_lazy.transactions (post_time);


create table test_lazy.account_balances_mat(
  name varchar primary key references test_lazy.accounts
    on update cascade
    on delete cascade,
  balance numeric(9,2) not null default 0,
  expiration_time timestamptz not null
);

create index on test_lazy.account_balances_mat (balance);
create index on test_lazy.account_balances_mat (expiration_time);

insert into test_lazy.account_balances_mat(name, expiration_time)
select name, '-Infinity'
from test_lazy.accounts;



create function test_lazy.account_insert() returns trigger
  security definer
  language plpgsql
as $$
  begin
    insert into test_lazy.account_balances_mat(name, expiration_time)
      values(new.name, 'Infinity');
    return new;
  end;
$$;

create trigger lazy_account_insert after insert on test_lazy.accounts
    for each row execute procedure test_lazy.account_insert();


create function test_lazy.transaction_insert()
  returns trigger
  security definer
  language plpgsql
as $$
  begin
    update test_lazy.account_balances_mat
    set expiration_time=new.post_time
    where name=new.name
      and new.post_time < expiration_time;
    return new;
  end;
$$;

create trigger lazy_transaction_insert after insert on test_lazy.transactions
    for each row execute procedure test_lazy.transaction_insert();


create function test_lazy.transaction_update()
  returns trigger
  security definer
  language plpgsql
as $$
  begin
    update test_lazy.account_balances_mat
    set expiration_time = '-Infinity'
    where name in (old.name, new.name)
      and expiration_time <> '-Infinity';
    raise notice 'whats up';
    return new;
  end;
$$;

create trigger lazy_transaction_update after update on test_lazy.transactions
    for each row execute procedure test_lazy.transaction_update();


create function test_lazy.transaction_delete()
  returns trigger
  security definer
  language plpgsql
as $$
  begin
    update test_lazy.account_balances_mat
    set expiration_time='-Infinity'
    where name=old.name
      and old.post_time <= expiration_time;

    return old;
  end;
$$;

create trigger lazy_transaction_delete after delete on test_lazy.transactions
    for each row execute procedure test_lazy.transaction_delete();


create function test_lazy.refresh_account_balance(_name varchar)
  returns test_lazy.account_balances_mat
  security definer
  language sql
as $$
  with t as (
    select
      coalesce(
        sum(amount) filter (where post_time <= current_timestamp),
        0
      ) as balance,
      coalesce(
        min(post_time) filter (where current_timestamp < post_time),
        'Infinity'
      ) as expiration_time
    from test_lazy.transactions
    where name=_name
  )
  update test_lazy.account_balances_mat
  set balance = t.balance,
    expiration_time = t.expiration_time
  from t
  where name=_name
  returning account_balances_mat.*;
$$;


create view test_lazy.account_balances as
select name, balance
from test_lazy.account_balances_mat
where current_timestamp < expiration_time
union all
select r.name, r.balance
from test_lazy.account_balances_mat abm
  cross join test_lazy.refresh_account_balance(abm.name) r
where abm.expiration_time <= current_timestamp;



select * from test_lazy.account_balances_mat;

insert into test_lazy.transactions (name, amount, post_time)
          select 'foo', 1, timestamp '2013-01-01'
union all select 'foo', 2, timestamp '2012-01-01'
union all select 'bar', 3, timestamp '2014-01-01'
;

-- update test_lazy.transactions set amount=5 where name='bar';

/*
insert into test_lazy.account_balances_mat(name, expiration_time)
select name, '-Infinity'
from test_lazy.accounts;
*/

select * from test_lazy.accounts;
select * from test_lazy.transactions;
select * from test_lazy.account_balances_mat;
select * from test_lazy.account_balances;
--select * from test_lazy.account_balances where balance < 0;

drop schema if exists test_lazy cascade;
