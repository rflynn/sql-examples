
begin;

/*

define a set of unit testing primitives

assert_equals(x, y)
assert_not_equals(x, y)
assert_raises(sql)
assert_raises(sql, exception_pattern)

*/

--
-- assert_equals
--

drop function if exists assert_equals(unknown, unknown);
create or replace function assert_equals(unknown, unknown) returns void as
$$
begin
    if $1::text = $2::text then
        return;
    else
        raise exception 'assert_equals failed: % != %', $1, $2;
    end if;
end;
$$
language plpgsql;

drop function if exists assert_equals(anyelement, anyelement);
create or replace function assert_equals(anyelement, anyelement) returns void as
$$
begin
    if $1::text = $2::text then
        return;
    else
        raise exception 'assert_equals failed: % != %', $1, $2;
    end if;
end;
$$
language plpgsql;

-- test assert_equals

select assert_equals(true, true);
select assert_equals(false, false);
select assert_equals(0, 0);
select assert_equals(0.0, 0.0);
select assert_equals(2147483648,
                     2147483648);
select assert_equals(now()::date, now()::date);
select assert_equals(now()::timestamp with time zone, now()::timestamp with time zone);
select assert_equals(now()::timestamp without time zone, now()::timestamp without time zone);
select assert_equals('', '');
select assert_equals(upper('abc'), 'ABC'::text);
select assert_equals(0::oid, 0::oid);
select assert_equals('foo'::name, 'foo'::name);
select assert_equals('{}'::jsonb, '{}'::jsonb);
select assert_equals('{"a":1,"b":2}'::jsonb, '{"b":2,"a":1}'::jsonb);


--
-- assert_not_equals
--

drop function if exists assert_not_equals(anyelement, anyelement);
create or replace function assert_not_equals(anyelement, anyelement) returns void as
$$
begin
    if $1::text != $2::text then
        return;
    else
        raise exception 'assert_not_equals failed: % = %', $1, $2;
    end if;
end;
$$
language plpgsql;


select assert_not_equals(true, false);
select assert_not_equals(false, true);

select assert_not_equals(1, 2);

-- type mismatch
-- select assert_not_equals('', 0); -- doesn't work


--
-- assert_raises
--

drop function if exists assert_raises(text);
create or replace function assert_raises(sql text) returns void as
$$
declare
    err_text text;
begin
    execute $1::text;
    -- can't figure out a better way to handle non-exception...
    raise sqlclient_unable_to_establish_sqlconnection;
exception
    when sqlclient_unable_to_establish_sqlconnection then
        raise exception 'assert_raises failed: ran without exception: %', $1;
    when syntax_error then
        -- should never happen, re-raise these
        get stacked diagnostics err_text = MESSAGE_TEXT;
        raise syntax_error using message=err_text;
    when others then
        get stacked diagnostics err_text = MESSAGE_TEXT;
        raise notice 'caught: "%"', err_text;
        return;  -- exception caught, function success
end;
$$
language plpgsql;

create or replace function assert_raises(sql text, expected_error text) returns void as
$$
declare
    err_text text;
begin
    execute $1::text;
    -- can't figure out a better way to handle non-exception...
    raise sqlclient_unable_to_establish_sqlconnection;
exception
    when sqlclient_unable_to_establish_sqlconnection then
        raise exception 'assert_raises failed: ran without exception: %', $1;
    when others then
        get stacked diagnostics err_text = MESSAGE_TEXT;
        raise notice 'caught: "%"', err_text;
        if not (err_text ~ expected_error or err_text like expected_error) then
            raise exception 'assert_raises failed: unexpected exception (% != %): %', err_text, $2, $1;
        end if;
        return;  -- exception caught, function success
end;
$$
language plpgsql;

-- test assert_raises
select assert_raises('select 0/0'::text);
select assert_raises('select assert_equals(0, 1)'::text);
select assert_raises('select assert_raises(assert_equals(1, 2))'::text);

select assert_raises('select 0 / 0'::text, 'division by zero'::text);
select assert_raises('select assert_raises(''select 0 / 0''::text, ''wrong exception''::text)'::text,
                            'unexpected exception'::text);
select assert_raises('('::text, 'syntax error at end of input'::text);

commit;
