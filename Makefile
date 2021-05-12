CWD = $(shell pwd -P)
ROOT ?= $(realpath $(CWD)/../..)
PROJECT = crossbar

TIMEZONE_JSON = $(CWD)/priv/couchdb/schemas/timezone.json
COMPILE_MOAR = $(TIMEZONE_JSON)

CLEAN_MOAR = clean-port-request-scheduled-schema

all: compile

eunit: cb-test

test: cb-test

cb-test:
	$(MAKE) compile-test -C $(ROOT)/core/kazoo_endpoint/

timezone:
	@ERL_LIBS=$(ROOT)/deps/:$(ROOT)/core/:$(ROOT)/applications/ $(CWD)/scripts/timezones.escript

$(TIMEZONE_JSON):
	@ERL_LIBS=$(ROOT)/deps/:$(ROOT)/core/:$(ROOT)/applications/ $(CWD)/scripts/timezones.escript

clean-port-request-scheduled-schema:
	$(if $(wildcard $(COMPILE_MOAR)), rm $(COMPILE_MOAR))

include $(ROOT)/make/kz.mk
