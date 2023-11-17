%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2023, 2600Hz
%%% @doc Match list module
%%% Handle client requests for match list documents, api v2
%%%
%%%
%%% @author SIPLABS, LLC (Ilya Ashchepkov)
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_lists).

-export([init/0
        ,authorize/1, authorize/2, authorize/3, authorize/4
        ,allowed_methods/0, allowed_methods/1, allowed_methods/2, allowed_methods/3, allowed_methods/4
        ,resource_exists/0, resource_exists/1, resource_exists/2, resource_exists/3, resource_exists/4
        ,content_types_provided/1, content_types_provided/2, content_types_provided/3, content_types_provided/4, content_types_provided/5
        ,validate/1, validate/2, validate/3, validate/4, validate/5
        ,put/1, put/3
        ,post/2, post/4
        ,patch/2, patch/4
        ,delete/2, delete/3, delete/4
        ]).

-include("crossbar.hrl").

-define(CB_LIST, <<"lists/crossbar_listing">>).
-define(ENTRIES_VIEW, <<"lists/entries">>).
-define(CROSSBAR_LISTING_BY_OWNER_ID_TYPE, <<"crossbar_listings/by_ownerid_type">>).
-define(ENTRIES, <<"entries">>).
-define(VCARD, <<"vcard">>).
-define(PHOTO, <<"photo">>).
-define(TYPE_LIST, <<"list">>).
-define(TYPE_LIST_ENTRY, <<"list_entry">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    Bindings = [{<<"*.allowed_methods.lists">>, 'allowed_methods'}
               ,{<<"*.resource_exists.lists">>, 'resource_exists'}
               ,{<<"*.content_types_provided.lists">>, 'content_types_provided'}
               ,{<<"*.validate.lists">>, 'validate'}
               ,{<<"*.execute.put.lists">>, 'put'}
               ,{<<"*.execute.post.lists">>, 'post'}
               ,{<<"*.execute.patch.lists">>, 'patch'}
               ,{<<"*.execute.delete.lists">>, 'delete'}
               ,{<<"*.authorize.lists">>, 'authorize'}
               ],
    cb_modules_util:bind(?MODULE, Bindings),
    'ok'.

-spec allowed_methods() -> http_methods().
allowed_methods() ->
    [?HTTP_GET, ?HTTP_PUT].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_ListId) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_PATCH, ?HTTP_DELETE].

-spec allowed_methods(path_token(), path_token()) -> http_methods().
allowed_methods(_ListId, ?ENTRIES) ->
    [?HTTP_GET, ?HTTP_PUT, ?HTTP_DELETE].

-spec allowed_methods(path_token(), path_token(), path_token()) -> http_methods().
allowed_methods(_ListId, ?ENTRIES, _ListEntryId) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_PATCH, ?HTTP_DELETE].

-spec allowed_methods(path_token(), path_token(), path_token(), path_token()) -> http_methods().
allowed_methods(_ListId, ?ENTRIES, _ListEntryId, ?VCARD) ->
    [?HTTP_GET];
allowed_methods(_ListId, ?ENTRIES, _ListEntryId, ?PHOTO) ->
    [?HTTP_POST].

-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_ListId) -> 'true'.

-spec resource_exists(path_token(), path_token()) -> 'true'.
resource_exists(_ListId, ?ENTRIES) -> 'true'.

-spec resource_exists(path_token(), path_token(), path_token()) -> 'true'.
resource_exists(_ListId, ?ENTRIES, _EntryId) -> 'true'.

-spec resource_exists(path_token(), path_token(), path_token(), path_token()) -> 'true'.
resource_exists(_ListId, ?ENTRIES, _EntryId, ?VCARD) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Authorizes the incoming request, returning true if the requestor is
%% allowed to access the resource, or false if not.
%% @end
%%------------------------------------------------------------------------------
-spec authorize(cb_context:context()) ->
          'true' | {'stop', cb_context:context()}.
authorize(_Context) -> 'true'.

-spec authorize(cb_context:context(), path_token()) ->
          'true' | {'stop', cb_context:context()}.
authorize(Context, ListId) ->
    authorize_based_req_verb(Context, cb_context:req_verb(Context), ListId).

-spec authorize(cb_context:context(), path_token(), path_token()) ->
          'true' | {'stop', cb_context:context()}.
authorize(Context, ListId, ?ENTRIES) ->
    authorize_based_req_verb(Context, ?HTTP_GET, ListId).

-spec authorize(cb_context:context(), path_token(), path_token(), path_token()) ->
          'true' | {'stop', cb_context:context()}.
authorize(Context, ListId, ?ENTRIES, _EntryId) ->
    authorize_based_req_verb(Context, ?HTTP_GET, ListId).

-spec authorize_based_req_verb(cb_context:context(), http_method(), path_token()) ->
          'true' | {'stop', cb_context:context()}.
authorize_based_req_verb(Context, ?HTTP_GET, ListId) ->
    ContextResp = crossbar_doc:load(ListId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST)),
    Doc = cb_context:doc(ContextResp),
    OwnerId = kzd_lists:owner_id(Doc),
    case {maybe_admin(Context)
         ,auth_token_user_matches(Context, OwnerId)}
    of
        {'true', _} ->
            'true';
        {'false', 'true'} ->
            'true';
        {'false', 'false'} ->
            {'stop', cb_context:add_system_error('forbidden', Context)}
    end;
authorize_based_req_verb(Context, _ReqVerb, _ListId) ->
    case {cb_context:user_id(Context)
         ,maybe_admin(Context)}
    of
        {_UserId, 'true'} ->
            'true';
        {'undefined', 'false'} ->
            {'stop', cb_context:add_system_error('forbidden', Context)};
        {UserId, 'false'} ->
            case auth_token_user_matches(Context, UserId) of
                'true' -> 'true';
                'false' -> {'stop', cb_context:add_system_error('forbidden', Context)}
            end
    end.

-spec content_types_provided(cb_context:context()) ->
          cb_context:context().
content_types_provided(Context) ->
    Context.

-spec content_types_provided(cb_context:context(), path_token()) ->
          cb_context:context().
content_types_provided(Context, _) ->
    Context.

-spec content_types_provided(cb_context:context(), path_token(), path_token()) ->
          cb_context:context().
content_types_provided(Context, _, _) ->
    Context.

-spec content_types_provided(cb_context:context(), path_token(), path_token(), path_token()) ->
          cb_context:context().
content_types_provided(Context, _, _, _) ->
    Context.

-spec content_types_provided(cb_context:context(), path_token(), path_token(), path_token(), path_token()) ->
          cb_context:context().
content_types_provided(Context, _, ?ENTRIES, _, ?VCARD) ->
    cb_context:set_content_types_provided(Context
                                         ,[{'to_binary'
                                           ,[{<<"text">>, <<"x-vcard">>}
                                            ,{<<"text">>, <<"directory">>}
                                            ]
                                           }
                                          ]
                                         ).

-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_req(cb_context:req_verb(Context), Context, []).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, ListId) ->
    validate_req(cb_context:req_verb(Context), Context, [ListId]).

-spec validate(cb_context:context(), path_token(), path_token()) -> cb_context:context().
validate(Context, ListId, ?ENTRIES) ->
    validate_req(cb_context:req_verb(Context), Context, [ListId, ?ENTRIES]).

-spec validate(cb_context:context(), path_token(), path_token(), path_token()) -> cb_context:context().
validate(Context, ListId, ?ENTRIES, EntryId) ->
    validate_req(cb_context:req_verb(Context), Context, [ListId, ?ENTRIES, EntryId]).

-spec validate(cb_context:context(), path_token(), path_token(), path_token(), path_token()) -> cb_context:context().
validate(Context, ListId, ?ENTRIES, EntryId, ?VCARD) ->
    validate_req(cb_context:req_verb(Context), Context, [ListId, ?ENTRIES, EntryId, ?VCARD]).

-spec get_lists_unowned(cb_context:context())-> cb_context:context().
get_lists_unowned(Context) ->
    Options = [{'mapper', fun normalize_lists_unowned/3}
              ,'include_docs'
              ],
    crossbar_view:load(Context, ?CB_LIST, Options).

-spec normalize_lists_unowned(cb_context:context(), kz_json:object(), kz_json:objects()) -> kz_json:objects().
normalize_lists_unowned(Context, JObj, Acc) ->
    case kz_json:is_defined([<<"doc">>, <<"owner_id">>], JObj) of
        'true' -> Acc;
        'false' ->
            get_entries_by_list(Context, JObj, Acc)
    end.

-spec get_entries_by_list(cb_context:context(), kz_json:object(), kz_json:objects()) -> kz_json:objects().
get_entries_by_list(Context, JObj, Acc) ->
    format_list_entries(JObj, Acc
                       ,kz_datamgr:get_results(cb_context:account_id(Context)
                                              ,<<"lists/entries">>
                                              ,[{'key', kz_doc:id(JObj)}
                                               ,'include_docs'
                                               ]
                                              )
                       ).

format_list_entries(JObj, Acc, {'ok', []}) ->
    lager:info("no entries in ~s", [kz_doc:id(JObj)]),
    Values = [{<<"entries">>, []},
              {<<"list">>, kz_json:get_value(<<"value">>, JObj)}
             ],
    NewJObj = kz_json:from_list(Values),
    [NewJObj| Acc];
format_list_entries(JObj, Acc, {'ok', Entries}) ->
    Contacts = lists:foldl(fun add_entry/2
                          ,[]
                          ,Entries
                          ),
    Values = [{<<"entries">>, Contacts},
              {<<"list">>, kz_json:get_value(<<"value">>, JObj)}
             ],
    NewJObj = kz_json:from_list(Values),
    [NewJObj| Acc];
format_list_entries(JObj, Acc, {'error', _Reason}= _Error) ->
    lager:warning("failed to load entry documents for list ~s: ~p", [kz_doc:id(JObj), _Reason]),
    Values = [{<<"entries">>, []},
              {<<"list">>, kz_json:get_value(<<"value">>, JObj)}
             ],
    NewJObj = kz_json:from_list(Values),
    [NewJObj| Acc].

add_entry(ViewResult, AccE) ->
    Entry = kz_json:get_json_value(<<"doc">>, ViewResult),
    Values = [{<<"contacts">>, kzd_list_entries:contacts(Entry)}
             ,{<<"name">>, kzd_list_entries:name(Entry)}
             ],
    [kz_json:from_list(Values) | AccE].

-spec get_lists_owned(cb_context:context(), kz_term:api_ne_binary())-> cb_context:context().
get_lists_owned(Context, UserId) ->
    Options = [{'key', [UserId, ?TYPE_LIST]}
              ,{'mapper', fun normalize_lists_owned/3}
              ,'include_docs'
              ],
    crossbar_view:load(Context, ?CROSSBAR_LISTING_BY_OWNER_ID_TYPE, Options).

-spec normalize_lists_owned(cb_context:context(), kz_json:object(), kz_json:objects()) -> kz_json:objects().
normalize_lists_owned(Context, JObj, Acc) ->
    get_entries_by_list(Context, JObj, Acc).

-spec validate_req(http_method(), cb_context:context(), path_tokens()) -> cb_context:context().
validate_req(?HTTP_GET, Context, []) ->
    case cb_context:user_id(Context) of
        'undefined' ->
            get_lists_unowned(Context);
        UserId ->
            get_lists_owned(Context, UserId)
    end;
validate_req(?HTTP_PUT, Context, []) ->
    case cb_context:user_id(Context) of
        'undefined' ->
            validate_doc('undefined', ?TYPE_LIST, Context);
        UserId ->
            NewDoc = kzd_lists:set_owner_id(cb_context:req_data(Context), UserId),
            validate_doc('undefined', ?TYPE_LIST, cb_context:set_req_data(Context, NewDoc))
    end;

validate_req(?HTTP_GET, Context, [ListId]) ->
    crossbar_doc:load(ListId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST));
validate_req(?HTTP_DELETE, Context, [ListId]) ->
    Options = [{'key', ListId}
              ,{'should_paginate', 'false'}
              ,{'unchunkable', 'true'}
              ,{'mapper', crossbar_view:get_id_fun()}
              ],
    crossbar_view:load(Context, ?ENTRIES_VIEW, Options);
validate_req(?HTTP_POST, Context, [ListId]) ->
    validate_doc(ListId, ?TYPE_LIST, Context);
validate_req(?HTTP_PATCH, Context, [ListId] = Path) ->
    crossbar_doc:patch_and_validate(ListId, Context, fun(_Id, C) -> validate_req(?HTTP_POST, C, Path) end);

validate_req(?HTTP_GET, Context, [ListId, ?ENTRIES]) ->
    %% FIXME: why this doesn't normalize the db result??
    %% It is a list of objects, in which both the id and the value of each object are needed.
    Options = [{'key', ListId}
              ,{'should_paginate', 'false'}
              ,{'unchunkable', 'true'}
              ],
    crossbar_view:load(Context, ?ENTRIES_VIEW, Options);
validate_req(?HTTP_PUT, Context, [ListId, ?ENTRIES]) ->
    ReqData = kzd_list_entries:set_list_id(cb_context:req_data(Context), ListId),
    validate_doc('undefined', ?TYPE_LIST_ENTRY, cb_context:set_req_data(Context, ReqData));
validate_req(?HTTP_DELETE, Context, [ListId, ?ENTRIES]) ->
    Options = [{'key', ListId}
              ,{'should_paginate', 'false'}
              ,{'unchunkable', 'true'}
              ],
    crossbar_view:load(Context, ?ENTRIES_VIEW, Options);

validate_req(?HTTP_GET, Context, [_ListId, ?ENTRIES, EntryId]) ->
    crossbar_doc:load(EntryId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST_ENTRY));
validate_req(?HTTP_DELETE, Context, [_ListId, ?ENTRIES, EntryId]) ->
    crossbar_doc:load(EntryId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST_ENTRY));
validate_req(?HTTP_POST, Context, [_ListId, ?ENTRIES, EntryId]) ->
    validate_doc(EntryId, ?TYPE_LIST_ENTRY, Context);
validate_req(?HTTP_PATCH, Context, [_ListId, ?ENTRIES, EntryId] = Path) ->
    crossbar_doc:patch_and_validate(EntryId, Context, fun(_Id, C) -> validate_req(?HTTP_POST, C, Path) end);

validate_req(?HTTP_GET, Context, [_ListId, ?ENTRIES, EntryId, ?VCARD]) ->
    Context1 = crossbar_doc:load(EntryId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST_ENTRY)),
    JObj = cb_context:doc(Context1),
    JProfile = kz_json:get_json_value(<<"profile">>, JObj),
    JObj1 = kz_json:merge_jobjs(JObj, JProfile),
    JObj2 = kz_json:set_values(
              props:filter_empty([{<<"first_name">>, kz_json:get_value(<<"firstname">>, JObj1)}
                                 ,{<<"last_name">>, kz_json:get_value(<<"lastname">>, JObj1)}
                                 ,{<<"middle_name">>, kz_json:get_value(<<"middlename">>, JObj1)}
                                 ,{<<"nicknames">>, [kz_json:get_value(<<"displayname">>, JObj1)]}
                                 ])
             ,JObj1
             ),
    JObj3 = set_org(JObj2, Context1),
    JObj4 = set_photo(JObj3, Context1),
    RespData = kzd_users:to_vcard(JObj4),
    cb_context:set_resp_data(Context1, [RespData, "\n"]).

-spec validate_doc(kz_term:api_binary(), kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
validate_doc(Id, Type, Context) ->
    OnSuccess = fun(C) -> on_successful_validation(Id, Type, C) end,
    cb_context:validate_request_data(type_schema_name(Type), Context, OnSuccess).

-spec maybe_admin(cb_context:context()) -> boolean().
maybe_admin(Context) ->
    cb_context:is_account_admin(Context)
        orelse cb_context:is_superduper_admin(Context).

-spec auth_token_user_matches(cb_context:context(), kz_term:api_ne_binary())-> boolean().
auth_token_user_matches(Context, UserId)->
    cb_context:auth_user_id(Context) =:= UserId.

-spec delete(cb_context:context(), path_token()) -> cb_context:context().
delete(Context, ListId) ->
    _ = delete(Context, ListId, ?ENTRIES),
    Context1 = crossbar_doc:load(ListId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST_ENTRY)),
    case cb_context:resp_status(Context1) of
        'success' ->
            crossbar_doc:delete(Context1);
        _ ->
            Context1
    end.

-spec delete(cb_context:context(), path_token(), path_token()) -> cb_context:context().
delete(Context, _ListId, ?ENTRIES) ->
    Docs = [kz_doc:id(Entry) || Entry <- cb_context:doc(Context)],
    AccountDb = kzs_util:format_account_db(cb_context:db_name(Context)),
    %% do we need 'soft' delete as in crossbar_doc?
    _ = kz_datamgr:del_docs(AccountDb, Docs),
    cb_context:set_resp_status(Context, 'success').

-spec delete(cb_context:context(), path_token(), path_token(), path_token()) -> cb_context:context().
delete(Context, _ListId, ?ENTRIES, _EntryId) ->
    crossbar_doc:delete(Context).

-spec put(cb_context:context()) -> cb_context:context().
put(Context) ->
    crossbar_doc:save(Context).

-spec put(cb_context:context(), path_token(), path_token()) -> cb_context:context().
put(Context, _ListId, ?ENTRIES) ->
    crossbar_doc:save(Context).

-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _ListId) ->
    crossbar_doc:save(Context).

-spec post(cb_context:context(), path_token(), path_token(), path_token()) -> cb_context:context().
post(Context, _ListId, ?ENTRIES, _EntryId) ->
    crossbar_doc:save(Context).

-spec patch(cb_context:context(), path_token()) -> cb_context:context().
patch(Context, _ListId) ->
    crossbar_doc:save(Context).

-spec patch(cb_context:context(), path_token(), path_token(), path_token()) -> cb_context:context().
patch(Context, _ListId, ?ENTRIES, _EntryId) ->
    crossbar_doc:save(Context).

-spec type_schema_name(kz_term:ne_binary()) -> kz_term:ne_binary().
type_schema_name(?TYPE_LIST) -> <<"lists">>;
type_schema_name(?TYPE_LIST_ENTRY) -> <<"list_entries">>.

-spec on_successful_validation(kz_term:api_binary(), kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
on_successful_validation('undefined', Type, Context) ->
    Doc = kz_doc:set_type(cb_context:doc(Context), Type),
    cb_context:set_doc(Context, Doc);
on_successful_validation(Id, Type, Context) ->
    crossbar_doc:load_merge(Id, Context, ?TYPE_CHECK_OPTION(Type)).

-spec set_org(kz_json:object(), cb_context:context()) -> kz_json:object().
set_org(JObj, Context) ->
    ListId = kz_json:get_value(<<"list_id">>, JObj),
    Context1 = crossbar_doc:load(ListId, Context, ?TYPE_CHECK_OPTION(?TYPE_LIST_ENTRY)),
    set_org(JObj, Context1, cb_context:resp_status(Context1), ListId).

-spec set_org(kz_json:object(), cb_context:context(), crossbar_status(), kz_term:ne_binary()) -> kz_json:object().
set_org(JObj, Context, 'success', _) ->
    case kz_json:get_value(<<"org">>, cb_context:doc(Context)) of
        'undefined' -> JObj;
        Val -> kz_json:set_value(<<"org">>, Val, JObj)
    end;
set_org(JObj, _, _, ListId) ->
    lager:debug("failed to load list ~p while loading list entry ~p",
                [ListId, kz_json:get_value(<<"id">>, JObj)]
               ),
    JObj.

-spec set_photo(kz_json:object(), cb_context:context()) -> kz_json:object().
set_photo(JObj, Context) ->
    %% This code is copied from cb_users. May be move it to crossbar_doc?
    DocId = kz_json:get_value(<<"_id">>, cb_context:doc(Context)),
    Attach = crossbar_doc:load_attachment(DocId, ?PHOTO, ?TYPE_CHECK_OPTION(?TYPE_LIST_ENTRY), Context),
    case cb_context:resp_status(Attach) of
        'error' -> JObj;
        'success' ->
            Data = cb_context:resp_data(Attach),
            CT = kz_doc:attachment_content_type(cb_context:doc(Context), ?PHOTO),
            kz_json:set_value(?PHOTO, kz_json:from_list([{CT, Data}]), JObj)
    end.
