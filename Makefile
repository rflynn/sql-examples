# vim: set ts=8 noet:

.PHONY: test test-postgres

test:
	sudo su postgres /bin/bash -c 'make test-postgres && make test-postgres'

test-postgres:
	psql -v ON_ERROR_STOP=1 -a < assert.sql
	psql -v ON_ERROR_STOP=1 -a < date_intervals_between_2_timestamps.sql
	psql -v ON_ERROR_STOP=1 -a < date_schedule_around_weekends_and_holidays.sql
	psql -v ON_ERROR_STOP=1 -a < date_years_identical.sql
	psql -v ON_ERROR_STOP=1 -a < lazy.sql
	psql -v ON_ERROR_STOP=1 -a < list_table_view_dependencies_psql.sql
	psql -v ON_ERROR_STOP=1 -a < pg_list_entities.sql
