%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2025, 2600Hz
%%% @doc Crossbar API for pivot.
%%% @author James Aimonetti
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_pivot).

-export([init/0
        ,allowed_methods/1, allowed_methods/2
        ,resource_exists/1, resource_exists/2
        ,validate/2, validate/3
        ]).

-include("crossbar.hrl").

-define(CB_DEBUG_LIST, <<"pivot/debug_listing">>).
-define(CB_FIRST_ITERATION, <<"pivot/first_iteration">>).

-define(DEBUG_PATH_TOKEN, <<"debug">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.allowed_methods.pivot">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.pivot">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.pivot">>, ?MODULE, 'validate').

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(?DEBUG_PATH_TOKEN) ->
    [?HTTP_GET].

-spec allowed_methods(path_token(), path_token()) -> http_methods().
allowed_methods(?DEBUG_PATH_TOKEN, _UUID) ->
    [?HTTP_GET].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource.
%% For example:
%%
%% ```
%%    /pivot => []
%%    /pivot/foo => [<<"foo">>]
%%    /pivot/foo/bar => [<<"foo">>, <<"bar">>]
%% '''
%% @end
%%------------------------------------------------------------------------------

-spec resource_exists(path_token()) -> 'true'.
resource_exists(?DEBUG_PATH_TOKEN) -> 'true'.

-spec resource_exists(path_token(), path_token()) -> 'true'.
resource_exists(?DEBUG_PATH_TOKEN, _) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Check the request (request body, query string params, path tokens, etc)
%% and load necessary information.
%% /pivot might load a list of pivot objects
%% /pivot/123 might load the pivot object 123
%% Generally, use crossbar_doc to manipulate the cb_context{} record
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, ?DEBUG_PATH_TOKEN) ->
    debug_summary(Context).

-spec validate(cb_context:context(), path_token(), path_token()) ->cb_context:context().
validate(Context, ?DEBUG_PATH_TOKEN, CallId) ->
    debug_read(Context, CallId).

%%------------------------------------------------------------------------------
%% @doc Load instances from the modb database
%% Supports filtering all calls within created_from and created_to
%% The merge action request and response is handled by couchdb map/reduce
%% @end
%%------------------------------------------------------------------------------
-spec debug_summary(cb_context:context()) -> cb_context:context().
debug_summary(Context) ->
    ViewOptions = [{'mapper', crossbar_view:get_value_fun()}
                  ,{'limit', limit_by_page_size(Context)}
                  ,{'reduce', 'true'}
                  ,{'group_level', 1}
                  | maybe_add_range_keymap_nil(Context)
                  ],
    maybe_normalize_debug_results(crossbar_view:load_modb(Context, ?CB_FIRST_ITERATION, ViewOptions)).

%%------------------------------------------------------------------------------
%% @doc Pivot debugs are store in two documents, request debug and response
%% debug. If page_size is requested set limit accordingly to return
%% both documents.
%% @end
%%------------------------------------------------------------------------------
-spec limit_by_page_size(cb_context:context()) -> kz_term:api_pos_integer().
limit_by_page_size(Context) ->
    case cb_context:pagination_page_size(Context) of
        Size when is_integer(Size), Size > 0 -> Size;
        _ -> 'undefined'
    end.

%%------------------------------------------------------------------------------
%% @doc Load an instance from the database
%% @end
%%------------------------------------------------------------------------------
-spec debug_read(cb_context:context(), kz_term:ne_binary()) -> cb_context:context().
debug_read(Context, ?MATCH_MODB_PREFIX(Year, Month, CallId)) ->
    AccountMODB = kazoo_modb:get_modb(cb_context:account_id(Context), Year, Month),
    Options = debug_read_modb_options(AccountMODB, CallId),
    Context1 = crossbar_view:load(Context, ?CB_DEBUG_LIST, Options),
    case cb_context:resp_status(Context1) of
        'success' ->
            RespData = cb_context:resp_data(Context1),
            cb_context:set_resp_data(Context1, lists:reverse(RespData));
        _Status -> Context1
    end;
debug_read(Context, CallId) ->
    ViewOptions = debug_read_callid_options(CallId),
    crossbar_view:load_modb(Context, ?CB_DEBUG_LIST, ViewOptions).

debug_read_modb_options(AccountMODB, CallId) ->
    [{'databases', [AccountMODB]}
    ,{'endkey', [CallId, kz_json:new()]}
    ,{'mapper', fun normalize_debug_read/2}
    ,{'startkey', [CallId]}
    ,{'field_key', 'filtermap'}
    ,'include_docs'
    ].

debug_read_callid_options(CallId) ->
    [{'mapper', fun normalize_debug_read/2}
    ,{'range_keymap', CallId}
    ,{'unchunkable', 'true'}
    ,{'field_key', 'filtermap'}
    ,'include_docs'
    ].

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec maybe_normalize_debug_results(cb_context:context()) -> cb_context:context().
maybe_normalize_debug_results(Context) ->
    case cb_context:resp_status(Context) of
        'success' -> normalize_debug_results(Context);
        _ -> Context
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec normalize_debug_results(cb_context:context()) -> cb_context:context().
normalize_debug_results(Context) ->
    Dir = crossbar_view:direction(Context),
    RespData = lists:map(fun(JObj) ->
                                 kz_json:set_value(<<"debug_id">>, debug_id(JObj), JObj)
                         end, cb_context:resp_data(Context)
                        ),
    cb_context:setters(Context
                      ,[{fun cb_context:set_resp_data/2, lists:sort(fun(A, B) -> sort_by_created(A, B, Dir) end, RespData)}
                       ,fun fix_page_size/1
                       ]
                      ).

-spec sort_by_created(kz_json:object(), kz_json:object(), kz_view:direction()) -> boolean().
sort_by_created(A, B, 'ascending') ->
    kz_json:get_integer_value(<<"created">>, A, 0) < kz_json:get_integer_value(<<"created">>, B, 1);
sort_by_created(A, B, 'descending') ->
    kz_json:get_integer_value(<<"created">>, A, 0) > kz_json:get_integer_value(<<"created">>, B, 1).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec fix_page_size(cb_context:context()) -> cb_context:context().
fix_page_size(Context) ->
    RespEnv = cb_context:resp_envelope(Context),
    RespData = cb_context:resp_data(Context),
    Size = erlang:length(RespData),
    cb_context:set_resp_envelope(Context
                                ,kz_json:set_value(<<"page_size">>, Size, RespEnv)
                                ).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec normalize_debug_read(kz_json:object(), kz_json:objects()) -> kz_json:objects().
normalize_debug_read(JObj, Acc) ->
    [add_metadata_fields(kz_json:get_json_value(<<"doc">>, JObj)) | Acc].

%%%%------------------------------------------------------------------------------
%%%% @doc
%%%% @end
%%%%------------------------------------------------------------------------------
-spec maybe_add_range_keymap_nil(cb_context:context()) -> [] | [{'range_keymap', 'nil'}].
maybe_add_range_keymap_nil(Context) ->
    Queries = cb_context:query_string(Context),
    Keys = kz_json:get_keys(Queries),
    case not lists:member(<<"created_from">>, Keys)
        andalso not lists:member(<<"created_to">>, Keys) of
        'true' -> [{'range_keymap', 'nil'}];
        'false' -> []
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec add_metadata_fields(kz_json:object()) -> kz_json:object().
add_metadata_fields(JObj) ->
    Routines = [fun add_created/2
               ,fun add_node/2
               ,fun add_debug_id/2
               ],
    lists:foldl(fun(F, Acc) -> F(JObj, Acc) end
               ,JObj
               ,Routines
               ).

-spec add_created(kz_json:object(), kz_json:object()) -> kz_json:object().
add_created(JObj, Acc) ->
    kz_json:set_value(<<"created">>, kz_doc:created(JObj), Acc).

-spec add_node(kz_json:object(), kz_json:object()) -> kz_json:object().
add_node(JObj, Acc) ->
    Node = kz_json:get_value([<<"pvt_node">>], JObj),
    kz_json:set_value(<<"node">>, Node, Acc).

-spec add_debug_id(kz_json:object(), kz_json:objects()) -> kz_json:object().
add_debug_id(JObj, Acc) ->
    kz_json:set_value(<<"debug_id">>, debug_id(JObj), Acc).

-spec debug_id(kz_json:object()) -> kz_term:ne_binary().
debug_id(JObj) ->
    Created = kz_json:get_first_defined([<<"created">>, <<"pvt_created">>], JObj),
    CallId = kz_json:get_value(<<"call_id">>, JObj),
    {{Year, Month, _}, _} = calendar:gregorian_seconds_to_datetime(Created),
    ?MATCH_MODB_PREFIX(kz_term:to_binary(Year), kz_date:pad_month(Month), CallId).
