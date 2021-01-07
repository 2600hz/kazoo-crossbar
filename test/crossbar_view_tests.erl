%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2020, 2600Hz
%%% @doc
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(crossbar_view_tests).

-include_lib("eunit/include/eunit.hrl").

has_valid_dbs_test_() ->
    Test = fun crossbar_view:has_valid_dbs/1,
    Options = fun(Dbs) -> [{'databases', Dbs}] end,
    Context = cb_context:new(),
    AssertInvalid = fun(Dbs) -> ?_assert(check_invalid_db_response(Test({Context, Options(Dbs)}))) end,
    AssertValid = fun(Dbs) -> ?_assert(check_valid_db_response(Test({Context, Options(Dbs)}))) end,

    [{"Invalid databases value"
     ,[AssertInvalid([])
      ,AssertInvalid("invalid-db-name")
      ,AssertInvalid(["invalid-db-name"])
      ,AssertInvalid('invalid-db-name')
      ,AssertInvalid(['invalid-db-name'])
      ]
     }
    ,{"Valid databases value"
     ,[AssertValid(<<"valid-db-name">>)
      ,AssertValid([<<"valid-db-name">>])
      ]
     }
    ].

check_invalid_db_response({'error', Context}) ->
    ErrorMsg = <<"invalid_db_name">>,
    'error' = cb_context:resp_status(Context),
    500 = cb_context:resp_error_code(Context),
    'true' = kz_json:are_equal(cb_context:resp_data(Context)
                              ,kz_json:from_list([{<<"message">>, ErrorMsg}])
                              ),
    ErrorMsg =:= cb_context:resp_error_msg(Context).

check_valid_db_response({'ok', {_Context, _Options}}) ->
    'true'.
