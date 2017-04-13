# vim: set ts=8 noet:

test:
	sudo su - postgres "make test-postgres"

test-postgres:
	psql < assert.sql
