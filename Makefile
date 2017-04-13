# vim: set ts=8 noet:

.PHONY: test test-postgres

test:
	sudo su postgres /bin/bash -c 'make test-postgres && make test-postgres'

test-postgres:
	psql -v ON_ERROR_STOP=1 -a < assert.sql
