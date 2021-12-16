CWD = $(shell pwd -P)
ROOT ?= $(realpath $(CWD)/../..)
PROJECT = crossbar

DEPS_LIST_TXT = $(CWD)/priv/deps_list.txt

COMPILE_MOAR = priv/couchdb/schemas/port_requests.to_scheduled.json $(DEPS_LIST_TXT)
CLEAN_MOAR = clean-port-request-scheduled-schema $(DEPS_LIST_TXT)

all: compile $(DEPS_LIST_TXT)

eunit: cb-test

test: cb-test

cb-test:
	$(MAKE) compile-test -C $(ROOT)/core/kazoo_endpoint/

priv/couchdb/schemas/port_requests.to_scheduled.json:
	@ERL_LIBS=$(ROOT)/deps/:$(ROOT)/core/:$(ROOT)/applications/ priv/port-request-scheduled-schema.escript

clean-port-request-scheduled-schema:
	$(if $(wildcard $(COMPILE_MOAR)), rm $(COMPILE_MOAR))

deps_list:
	@$(CWD)/scripts/list_deps.escript $(DEPS_LIST_TXT) $(ROOT)/deps

$(DEPS_LIST_TXT):
	@$(CWD)/scripts/list_deps.escript $(DEPS_LIST_TXT) $(ROOT)/deps

include $(ROOT)/make/kz.mk
