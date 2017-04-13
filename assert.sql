
begin;

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

drop function if exists assert_equals(text, text);
create or replace function assert_equals(text, text) returns void as
$$
begin
    if $1 = $2 then
        return;
    else
        raise exception 'assert_equals failed: % != %', $1, $2;
    end if;
end;
$$
language plpgsql;

drop function if exists assert_equals(numeric, numeric);
create or replace function assert_equals(numeric, numeric) returns void as
$$
begin
    if $1 = $2 then
        return;
    else
        raise exception 'assert_equals failed: % != %', $1, $2;
    end if;
end;
$$
language plpgsql;

drop function if exists assert_equals(boolean, boolean);
create or replace function assert_equals(boolean, boolean) returns void as
$$
begin
    if $1 = $2 then
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
select assert_equals(upper('abc'), 'ABC'::text);
select assert_equals(0, 0.0);


--
-- assert_not_equals
--

create or replace function assert_not_equals(unknown, unknown) returns void as
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

create or replace function assert_not_equals(numeric, numeric) returns void as
$$
begin
    if $1 != $2 then
        return;
    else
        raise exception 'assert_not_equals failed: % = %', $1, $2;
    end if;
end;
$$
language plpgsql;

create or replace function assert_not_equals(bool, bool) returns void as
$$
begin
    if $1 != $2 then
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
        return;  -- exception caught, function success
end;
$$
language plpgsql;

-- test assert_raises
select assert_raises('select 0/0'::text);
select assert_raises('select assert_equals(0, 1)'::text);
select assert_raises('select assert_raises(assert_equals(1, 2))'::text);


--
-- assert_raises_regexp
--

create or replace function assert_raises_regexp(sql text, expected_error text) returns void as
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
        -- raise warning 'The stack trace of the error is: "%"', err_text;
        if err_text !~ expected_error then
            raise exception 'assert_raises failed: unexpected exception (% != %): %', err_text, $2, $1;
        end if;
        return;  -- exception caught, function success
end;
$$
language plpgsql;

-- test assert_raises
select assert_raises_regexp('select 0 / 0'::text, 'division by zero'::text);
select assert_raises_regexp('select assert_raises_regexp(''select 0 / 0''::text, ''wrong exception''::text)'::text,
                            'unexpected exception'::text);
select assert_raises_regexp('('::text, 'syntax error at end of input'::text);

commit;
