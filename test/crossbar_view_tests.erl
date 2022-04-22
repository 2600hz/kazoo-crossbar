%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @doc
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(crossbar_view_tests).

-include_lib("eunit/include/eunit.hrl").

-spec has_valid_dbs_test_() -> list().
has_valid_dbs_test_() ->
    Context = cb_context:new(),
    EmptyDbContext = cb_context:set_db_name(Context, <<>>),
    DbContext = cb_context:set_db_name(Context, <<"system_config">>),

    [{"Invalid databases value"
     ,[?_assertEqual({'no_db', []}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({Context, []})
                      )
                    )
      ,?_assertEqual({'no_db', []}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({Context, [{'databases', [<<>>]}]})
                      )
                    )
      ,?_assertEqual({'error', <<"internal_error">>}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({Context, [{'databases', 'atom'}]})
                      )
                    )
      ,?_assertEqual({'no_db', []}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({EmptyDbContext, [{'databases', ['marble']}]})
                      )
                    )
      ,?_assertEqual({'no_db', []}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({EmptyDbContext, [{'databases', <<>>}]})
                      )
                    )
      ]
     }
    ,{"Valid databases value"
     ,[?_assertEqual({'ok', {<<"system_config">>, [<<"system_config">>]}}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({DbContext, [{'databases', <<>>}]})
                      )
                    )
      ,?_assertEqual({'ok', {<<"system_config">>, [<<"port_requests">>]}}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({DbContext, [{'databases', <<"port_requests">>}]})
                      )
                    )
      ,?_assertEqual({'ok', {<<"system_config">>, [<<"port_requests">>]}}
                    ,get_valid_databases(
                       crossbar_view:has_valid_dbs({DbContext, [{'databases', [<<"port_requests">>]}]})
                      )
                    )
      ]
     }
    ].

get_valid_databases({'error', Context}) ->
    {cb_context:resp_status(Context), cb_context:resp_error_msg(Context)};
get_valid_databases({'no_db', Context}) ->
    {'no_db', cb_context:resp_data(Context)};
get_valid_databases({'ok', {Context, Options}}) ->
    {'ok', {cb_context:db_name(Context), props:get_value('databases', Options)}}.
