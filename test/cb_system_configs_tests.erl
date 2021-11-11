%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2021, 2600Hz
%%% @doc
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_system_configs_tests).

-include_lib("eunit/include/eunit.hrl").

-define(DIALPLAN_KEY, <<"^(2\\d{6})$">>).
-define(DIALPLAN_VALUE, {[{<<"prefix">>,<<"+7812">>},{<<"name">>,<<"test">>}]}).

validate_document_test_() ->
    {'setup',
     fun set_context/0,
     fun set_request_data/1,
     fun validate_document/1
    }.

validate_document(Context) ->
    Resp = cb_system_configs:validate(Context, <<"dialplans">>),
    [?_assertMatch({'ok', _}, cb_context:response(Resp))].

set_context() ->
    cb_context:new().

set_request_data(Context) ->
    JObj = kz_json:new(),
    Data = kz_json:set_value(?DIALPLAN_KEY, ?DIALPLAN_VALUE, JObj),
    RequestContext = cb_context:set_req_verb(Context, <<"POST">>),
    cb_context:set_req_data(RequestContext, Data).