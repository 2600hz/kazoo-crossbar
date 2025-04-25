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
        ,allowed_methods/0, allowed_methods/1, allowed_methods/2
        ,resource_exists/0, resource_exists/1, resource_exists/2
        ,validate/1, validate/2, validate/3
        ,put/1
        ,post/2
        ,patch/2
        ,delete/2
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
    _ = cb_modules_util:bind(?MODULE, [{<<"*.allowed_methods.pivot">>, 'allowed_methods'}
                                      ,{<<"*.resource_exists.pivot">>, 'resource_exists'}
                                      ,{<<"*.validate.pivot">>, 'validate'}
                                      ,{<<"*.execute.put.pivot">>, 'put'}
                                      ,{<<"*.execute.post.pivot">>, 'post'}
                                      ,{<<"*.execute.patch.pivot">>, 'patch'}
                                      ,{<<"*.execute.delete.pivot">>, 'delete'}
                                      ]),
    'ok'.

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods() -> http_methods().
allowed_methods() ->
    [?HTTP_GET, ?HTTP_PUT].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(?DEBUG_PATH_TOKEN) ->
    [?HTTP_GET];
allowed_methods(_PivotId) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_PATCH, ?HTTP_DELETE].

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

-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(?DEBUG_PATH_TOKEN) -> 'true';
resource_exists(_PivotId) -> 'true'.

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

-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_pivot(Context, cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, ?DEBUG_PATH_TOKEN) ->
    debug_summary(Context);
validate(Context, PivotId) ->
    validate_pivot(Context, PivotId, cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token(), path_token()) ->cb_context:context().
validate(Context, ?DEBUG_PATH_TOKEN, CallId) ->
    debug_read(Context, CallId).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_pivot(cb_context:context(), path_token()) -> cb_context:context().
validate_pivot(Context, ?HTTP_GET) ->
    load_pivot_summary(Context);
validate_pivot(Context, ?HTTP_PUT) ->
    validate_request('undefined', Context).

-spec validate_pivot(cb_context:context(), kz_term:ne_binary(), path_token()) -> cb_context:context().
validate_pivot(Context, DocId, ?HTTP_GET) ->
    load_pivot(DocId, Context);
validate_pivot(Context, DocId, ?HTTP_POST) ->
    validate_request(DocId, Context);
validate_pivot(Context, DocId, ?HTTP_PATCH) ->
    validate_patch(DocId, Context);
validate_pivot(Context, DocId, ?HTTP_DELETE) ->
    load_pivot(DocId, Context).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is PUT, execute the actual action, usually a db save.
%% @end
%%------------------------------------------------------------------------------
-spec put(cb_context:context()) -> cb_context:context().
put(Context) ->
    crossbar_doc:save(Context).

-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _CallflowId) ->
    crossbar_doc:save(Context).

-spec patch(cb_context:context(), path_token()) -> cb_context:context().
patch(Context, _CallflowId) ->
    crossbar_doc:save(Context).

-spec delete(cb_context:context(), path_token()) -> cb_context:context().
delete(Context, _PivotId) ->
    crossbar_doc:delete(Context).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_patch(kz_term:api_binary(), cb_context:context()) -> cb_context:context().
validate_patch(PivotId, Context) ->
    crossbar_doc:patch_and_validate(PivotId, Context, fun validate_request/2).

%%------------------------------------------------------------------------------
%% @doc Attempt to load list of accounts, each summarized. Or a specific
%% account summary.
%% @end
%%------------------------------------------------------------------------------
-spec load_pivot_summary(cb_context:context()) -> cb_context:context().
load_pivot_summary(Context) ->
    Options = [{'doc_type', kzd_pivot:pvt_type()}
              ,{'mapper', crossbar_view:get_value_fun()}
              ],
    Selector = [{'start', [{<<"doc_type">>, kzd_pivot:pvt_type()}]}
               ,{'end', [{<<"doc_type">>, kzd_pivot:pvt_type()}]}
               ],
    crossbar_view:find(Context, <<"crossbar_listings/by_type_id">>, Selector, Options).

%%------------------------------------------------------------------------------
%% @doc Load a pivot document from the database
%% @end
%%------------------------------------------------------------------------------

-spec load_pivot(kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
load_pivot(PivotId, Context) ->
    crossbar_doc:load(PivotId, Context, ?TYPE_CHECK_OPTION(kzd_pivot:pvt_type())).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_request(kz_term:api_binary(), cb_context:context()) -> cb_context:context().
validate_request(PivotId, Context) ->
    check_pivot_schema(PivotId, Context).

%%------------------------------------------------------------------------------
%% @doc Load an instance from the database
%% Proper pagination is merely impossible for this API since we debugs
%% are in two documents, setting limit to 2 * PageSize is a bad choice.
%% What if the response or even the request debug document is not exists?
%% @end
%%------------------------------------------------------------------------------
-spec debug_summary(cb_context:context()) -> cb_context:context().
debug_summary(Context) ->
    ViewOptions = [{'mapper', crossbar_view:get_value_fun()}
                  ,{'range_keymap', 'nil'}
                  ,{'limit', limit_by_page_size(Context)}
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
        Size when is_integer(Size), Size > 0 ->
            Size * 2;
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
    {_, RespData} = lists:foldl(fun normalize_debug_results_fold/2, {sets:new(), []}, cb_context:resp_data(Context)),
    cb_context:setters(Context
                      ,[{fun cb_context:set_resp_data/2, lists:sort(fun(A, B) -> sort_by_created(A, B, Dir) end, RespData)}
                       ,fun fix_page_size/1
                       ]
                      ).

%%------------------------------------------------------------------------------
%% @doc Since view key is Call-ID, we're sure debug docs for the same Call-ID
%% are adjacent to each other. If we previously visited the Call-ID
%% the next doc with the same Call-ID are merged with list's head.
%% @end
%%------------------------------------------------------------------------------
-spec normalize_debug_results_fold(kz_json:object(), {sets:set(), kz_json:objects()}) -> {sets:set(), kz_json:objects()}.
normalize_debug_results_fold(JObj, {Set, []}) ->
    CallId = kz_json:get_value(<<"call_id">>, JObj),
    NewJObj = kz_json:set_value(<<"debug_id">>, debug_id(JObj), JObj),

    {sets:add_element(CallId, Set), [NewJObj]};
normalize_debug_results_fold(JObj, {Set, [H|Rest]=JObjAcc}) ->
    CallId = kz_json:get_value(<<"call_id">>, JObj),
    NewJObj = kz_json:set_value(<<"debug_id">>, debug_id(JObj), JObj),

    case sets:is_element(CallId, Set) of
        'false' -> {sets:add_element(CallId, Set), [NewJObj|JObjAcc]};
        'true' -> {Set, [kz_json:merge_jobjs(H, NewJObj)|Rest]}
    end.

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

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------

-spec check_pivot_schema(kz_term:api_binary(), cb_context:context()) -> cb_context:context().
check_pivot_schema(PivotId, Context) ->
    OnSuccess = fun(C) -> on_successful_validation(PivotId, C) end,
    cb_context:validate_request_data(<<"pivot">>, Context, OnSuccess).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------

-spec on_successful_validation(kz_term:api_binary(), cb_context:context()) ->
          cb_context:context().
on_successful_validation('undefined', Context) ->
    Props = [{<<"pvt_type">>, kzd_pivot:pvt_type()}],
    cb_context:set_doc(Context, kz_json:set_values(Props, cb_context:doc(Context)));
on_successful_validation(PivotId, Context) ->
    crossbar_doc:load_merge(PivotId, Context, ?TYPE_CHECK_OPTION(kzd_pivot:pvt_type())).
