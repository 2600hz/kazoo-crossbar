%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2012-2022, 2600Hz
%%% @doc
%%% @author Peter Defebvre
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_apps_util).

-export([allowed_apps/1
        ,allowed_apps/2
        ]).
-export([allowed_app/2]).
-export([load_default_apps/0
        ,load_default_app/1
        ,ensure_master_account_id/2
        ]).
-export([create_apps_store_doc/1]).

-export([app_whitelabel_doc_id/1]).
-export([find_attachment/2]).

-include("crossbar.hrl").

-define(CB_APPS_STORE_LIST, <<"apps_store/crossbar_listing">>).

-type apps_map() :: #{kz_term:ne_binary() := kz_json:object()}.
-type apps() :: kz_json:objects() | apps_map().

%%------------------------------------------------------------------------------
%% @doc Get allowed applications from service plans.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_apps(kz_term:ne_binary()) -> kz_json:objects().
allowed_apps(AccountId) ->
    allowed_apps(AccountId, 'undefined').

-spec allowed_apps(kz_term:ne_binary(), kz_term:api_ne_binary()) -> kz_json:objects().
allowed_apps(AccountId, UserId) ->
    allowed_apps(AccountId, UserId, load_default_apps('true')).

%%------------------------------------------------------------------------------
%% @doc Get an application object if allowed.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_app(kz_term:ne_binary(), kz_term:ne_binary()) -> kz_term:api_object().
allowed_app(AccountId, AppId) ->
    case [App || App <- allowed_apps(AccountId, 'undefined', load_default_app(AppId, 'true')),
                 AppId =:= kz_doc:id(App)
         ]
    of
        [App|_] ->
            %% More than one service plan can have the same app, hence taking the head
            App;
        [] -> 'undefined'
    end.

-spec allowed_apps(kz_term:ne_binary(), kz_term:api_ne_binary(), apps_map()) -> kz_json:objects().
allowed_apps(_AccountId, _UserId, DefaultApps) when map_size(DefaultApps) =:= 0 ->
    [];
allowed_apps(AccountId, UserId, DefaultApps) ->
    Routines = [fun allowed_service_plan/3
               ,fun apps_whitelabel_override/3
               ,fun allowed_apps_store_doc/3
               ,fun allowed_whitelabel_doc/3
               ,fun allowed_master_account/3
               ],
    Apps = lists:foldl(fun(F, AppsMap) ->
                               F(AccountId, UserId, AppsMap)
                       end
                      ,DefaultApps
                      ,Routines
                      ),
    maps:fold(fun ret_allowed_apps/3, [], Apps).

-spec ret_allowed_apps(kz_term:ne_binary(), kz_json:object(), kz_json:objects()) -> kz_json:objects().
ret_allowed_apps(_AppId, AppJObj, Acc) ->
    case kzd_app:is_published(AppJObj) of
        'true' ->
            lager:debug("allowing access to ~s due to ~s"
                       ,[kzd_app:name(AppJObj)
                        ,kz_json:get_value(<<"authority">>, AppJObj, <<"unknown">>)
                        ]
                       ),
            [AppJObj | Acc];
        'false' ->
            lager:debug("disallowing access to ~s due to ~s"
                       ,[kzd_app:name(AppJObj)
                        ,kz_json:get_value(<<"authority">>, AppJObj, <<"unknown">>)
                        ]
                       ),
            [AppJObj | Acc]
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec apps_whitelabel_override(kz_term:ne_binary(), kz_term:api_binary(), apps_map()) -> apps_map().
apps_whitelabel_override(AccountId, _UserId, AppsMap) ->
    {'ok', MasterAccountId} = kapps_util:get_master_account_id(),
    case AccountId =:= MasterAccountId of
        'true' -> AppsMap;
        'false' ->
            Overrides = fetch_apps_whitelabel_overrides(AccountId, AppsMap),
            maps:map(merge_app_whitelabel(Overrides), AppsMap)
    end.

-spec fetch_apps_whitelabel_overrides(AccountId::kz_term:ne_binary(), AppsMap::apps_map()) -> Overrides::apps_map().
fetch_apps_whitelabel_overrides(AccountId, AppsMap) ->
    AppIds = [app_whitelabel_doc_id(AppId) || AppId <- maps:keys(AppsMap)],
    case kz_datamgr:open_docs(AccountId, AppIds) of
        {'ok', JObjs} ->
            maps:from_list(
              [{app_whitelabel_doc_id_to_app_id(kz_doc:id(Doc)), Doc}
               || JObj <- JObjs,
                  Doc <- [kz_json:get_json_value(<<"doc">>, JObj)],
                  Doc =/= 'undefined'
              ]
             );
        {'error', _Reason} ->
            lager:debug("failed to get app overrides for account ~s: ~p", [AccountId, _Reason]),
            #{}
    end.

-spec merge_app_whitelabel(apps_map()) ->
          fun((kz_term:ne_binary(), kz_json:object()) -> kz_json:object()).
merge_app_whitelabel(Overrides) ->
    DeleteKeys = [<<"publish">>, <<"allowed_users">>, <<"name">>],
    fun(AppId, AppJObj) ->
            Override = maps:get(AppId, Overrides, kz_json:new()),
            merge_attachment_wise(AppJObj
                                 ,kz_json:delete_keys(DeleteKeys, kz_doc:public_fields(Override, 'false'))
                                 ,<<"app_whitelabel">>
                                 ,kz_doc:id(Override)
                                 ,kz_doc:account_db(Override)
                                 ,kz_doc:attachments(Override)
                                 )
    end.

%%------------------------------------------------------------------------------
%% @doc Load the application list from the accounts service plan, or the
%% reseller if that is empty. Set the published parameter on each app doc,
%% loading the doc if missing and nnot from the master, if its set in the
%% service plan.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_service_plan(kz_term:ne_binary(), kz_term:api_ne_binary(), apps_map()) -> apps_map().
allowed_service_plan(AccountId, _UserId, AppsMap) ->
    ServicesApps = get_services_apps(AccountId),
    Props = [{<<"authority">>, <<"service_plan">>}],
    maps:map(fun(AppId, AppJObj) ->
                     case kz_json:is_true([AppId, <<"enabled">>], ServicesApps, 'undefined') of
                         'undefined' -> AppJObj;
                         'true' -> kzd_app:publish(kz_json:set_values(Props, AppJObj));
                         'false' -> kzd_app:unpublish(kz_json:set_values(Props, AppJObj))
                     end
             end
            ,ensure_allowed_service_apps(ServicesApps, AppsMap)
            ).

-spec ensure_allowed_service_apps(kz_json:object(), apps_map()) -> apps_map().
ensure_allowed_service_apps(ServicesApps, AppsMap) ->
    {'ok', MasterAccountId} = kapps_util:get_master_account_id(),
    kz_json:foldl(ensure_allowed_service_apps_fold(MasterAccountId), AppsMap, ServicesApps).

-spec ensure_allowed_service_apps_fold(kz_term:ne_binary()) ->
          fun((kz_term:ne_binary(), kz_json:object(), apps_map()) -> apps_map()).
ensure_allowed_service_apps_fold(MasterAccountId) ->
    fun(AppId, ServicesAppJObj, AppsMap) ->
            VendorId = kz_json:get_ne_binary_value(<<"vendor_id">>, ServicesAppJObj, MasterAccountId),
            Enabled = kz_json:is_true(<<"enabled">>, ServicesAppJObj, 'true'),
            case VendorId =/= MasterAccountId
                andalso Enabled
            of
                'true' -> add_service_app_doc(VendorId, AppId, AppsMap);
                'false' -> AppsMap
            end
    end.

-spec add_service_app_doc(kz_term:ne_binary(), kz_term:ne_binary(), apps_map()) -> apps_map().
add_service_app_doc(VendorId, AppId, AppsMap) ->
    case kzd_app:fetch(VendorId, AppId) of
        {'ok', VendorAppJObj} ->
            lager:debug("including service app ~s from ~s"
                       ,[kzd_app:name(VendorAppJObj), VendorId]
                       ),
            Props = [{<<"authority">>, <<"vendor_account">>}
                    ,{<<"pvt_account_id">>, VendorId}
                    ,{<<"pvt_account_db">>, kzs_util:format_account_db(VendorId)}
                    ],
            AppJObj = maps:get(AppId, AppsMap, kz_json:new()),
            AppsMap#{AppId => merge_attachment_wise(AppJObj
                                                   ,kz_json:set_values(Props, VendorAppJObj)
                                                   ,<<"service_plan">>
                                                   )
                    };
        {'error', _R} ->
            AppsMap
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec allowed_apps_store_doc(kz_term:ne_binary(), kz_term:api_binary(), apps_map()) -> apps_map().
allowed_apps_store_doc(AccountId, UserId, AppsMap) ->
    case kzd_apps_store:fetch(AccountId) of
        {'error', _R} ->
            lager:error("failed to fetch apps store doc in ~s : ~p"
                       ,[AccountId, _R]
                       ),
            AppsMap;
        {'ok', AppStoreJObj} ->
            maps:map(allowed_apps_store_doc_map(AccountId, UserId, AppStoreJObj)
                    ,AppsMap
                    )
    end.

-spec allowed_apps_store_doc_map(kz_term:ne_binary(), kz_term:api_binary(), kz_json:object()) ->
          fun((kz_term:ne_binary(), kz_json:object()) -> kz_json:object()).
allowed_apps_store_doc_map(AccountId, UserId, AppStoreJObj) ->
    fun(AppId, AppJObj) ->
            AppPermissions = kz_json:get_ne_json_value(AppId, kzd_apps_store:apps(AppStoreJObj)),
            case is_blacklisted(AppJObj, AppStoreJObj) of
                'true' ->
                    Props = [{<<"authority">>, <<"app_store_blacklist">>}],
                    kzd_app:unpublish(kz_json:set_values(Props, AppJObj));
                'false' when AppPermissions =:= 'undefined' -> AppJObj;
                'false' ->
                    Authority = kz_json:from_list([{<<"authority">>, <<"app_store">>}]),
                    IsPublished = kzd_app:is_published(AppJObj),
                    case is_authorized(AccountId, UserId, AppPermissions) of
                        'true' when IsPublished ->
                            kz_json:merge([kzd_app:publish(AppJObj), AppPermissions, Authority]);
                        'true' ->
                            kz_json:merge([AppJObj, AppPermissions]);
                        'false' ->
                            kz_json:merge([kzd_app:unpublish(AppJObj), AppPermissions, Authority])
                    end
            end
    end.

-spec is_authorized(kz_term:ne_binary(), kz_term:api_ne_binary(), kz_json:object()) -> boolean().
is_authorized(_, 'undefined', _) ->
    'true';
is_authorized(AccountId, UserId, AppPermissions) ->
    AllowedType = kzd_app:allowed_users(AppPermissions, <<"specific">>),
    SpecificIds = get_specific_ids(kzd_app:users(AppPermissions)),
    case {AllowedType, SpecificIds} of
        {<<"all">>, _} -> 'true';
        {<<"specific">>, []} -> 'false';
        {<<"specific">>, UserIds} ->
            lists:member(UserId, UserIds);
        {<<"admins">>, _} ->
            kzd_users:is_account_admin(AccountId, UserId);
        {_A, _U} ->
            lager:error("unknown data ~p : ~p", [_A, _U]),
            'false'
    end.

-spec get_specific_ids(kz_term:ne_binaries()) -> kz_term:ne_binaries().
get_specific_ids(UserIds) ->
    [UserId || UserId <- UserIds, is_binary(UserId)].

-spec is_blacklisted(kz_json:object(), kz_json:object()) -> boolean().
is_blacklisted(App, JObj) ->
    Blacklist = kzd_apps_store:blacklist(JObj),
    lists:member(kz_doc:id(App), Blacklist).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec allowed_whitelabel_doc(kz_term:ne_binary(), kz_term:api_binary(), apps_map()) -> apps_map().
allowed_whitelabel_doc(AccountId, _UserId, AppsMap) ->
    WhitelabelJObj = get_whitelabel_doc(AccountId),
    IsReseller = kz_services_reseller:is_reseller(AccountId),
    maps:map(fun(_, AppJObj) ->
                     case kzd_app:name(AppJObj) =:= <<"port">>
                         andalso (not IsReseller)
                         andalso kzd_whitelabel:hide_port(WhitelabelJObj)
                     of
                         'false' -> AppJObj;
                         'true' ->
                             Props = [{<<"authority">>, <<"whitelabel_hide_port">>}],
                             kzd_app:unpublish(kz_json:set_values(Props, AppJObj))
                     end
             end
            ,AppsMap
            ).

-spec get_whitelabel_doc(kz_term:ne_binary()) -> kz_json:object().
get_whitelabel_doc(AccountId) ->
    case kzd_whitelabel:fetch(AccountId) of
        {'ok', JObj} -> JObj;
        {'error', 'not_found'} ->
            kzd_whitelabel:new();
        {'error', _R} ->
            lager:error("failed to load whitelabel doc for ~s: ~p"
                       ,[AccountId, _R]
                       ),
            kzd_whitelabel:new()
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec allowed_master_account(kz_term:ne_binary(), kz_term:api_binary(), apps_map()) -> apps_map().
allowed_master_account(AccountId, _UserId, AppsMap) ->
    {'ok', MasterAccountId} = kapps_util:get_master_account_id(),
    case AccountId =:= MasterAccountId of
        'false' -> AppsMap;
        'true' ->
            Props = [{<<"authority">>, <<"super_admin">>}],
            maps:map(fun(_AppId, AppJObj) ->
                             kzd_app:publish(kz_json:set_values(Props, AppJObj))
                     end
                    ,AppsMap
                    )
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec load_default_apps() -> apps().
load_default_apps() ->
    load_default_apps('false').

-spec load_default_apps(ReturnAsMap::boolean()) -> apps().
load_default_apps(ReturnAsMap) ->
    {'ok', MasterAccountDb} = kapps_util:get_master_account_db(),
    case kz_datamgr:get_results(MasterAccountDb, ?CB_APPS_STORE_LIST, ['include_docs']) of
        {'ok', JObjs} ->
            return_load_default(MasterAccountDb, JObjs, ReturnAsMap);
        {'error', _E} ->
            lager:error("failed to lookup apps in ~s", [MasterAccountDb]),
            return_load_default(MasterAccountDb, [], ReturnAsMap)

    end.

-spec load_default_app(kz_term:ne_binary()) -> apps().
load_default_app(AppId) ->
    load_default_app(AppId).

-spec load_default_app(kz_term:ne_binary(), ReturnAsMap::boolean()) -> apps().
load_default_app(AppId, ReturnAsMap) ->
    {'ok', MasterAccountDb} = kapps_util:get_master_account_db(),
    case kz_datamgr:open_doc(MasterAccountDb, AppId) of
        {'ok', JObj} ->
            return_load_default(MasterAccountDb, [JObj], ReturnAsMap);
        {'error', _E} ->
            lager:error("failed to lookup app ~s in ~s", [AppId, MasterAccountDb]),
            return_load_default(MasterAccountDb, [], ReturnAsMap)
    end.

return_load_default(MasterAccountDb, JObjs, 'true') ->
    %% next line we use Doc as default because this function may be called from outside
    %% and app doc is directly opened
    maps:from_list(
      [{kz_doc:id(JObj), ensure_master_account_id(MasterAccountDb, kz_json:get_value(<<"doc">>, JObj, JObj))}
       || JObj <- JObjs
      ]
     );
return_load_default(MasterAccountDb, JObjs, 'false') ->
    [ensure_master_account_id(MasterAccountDb, kz_json:get_value(<<"doc">>, JObj, JObj))
     || JObj <- JObjs
    ].

-spec ensure_master_account_id(kz_term:ne_binary(), kz_json:object()) -> kz_json:object().
ensure_master_account_id(Account, Doc) ->
    AccountId = kzs_util:format_account_id(Account),
    AccountDb = kzs_util:format_account_db(Account),
    Props = [{<<"authority">>, <<"master_account">>}
            ,{[<<"pvt_app_attachments">>, <<"master">>, <<"_id">>], kz_doc:id(Doc)}
            ,{[<<"pvt_app_attachments">>, <<"master">>, <<"pvt_account_db">>], AccountDb}
            ,{[<<"pvt_app_attachments">>, <<"master">>, <<"_attachments">>], kz_doc:attachments(Doc)}
            ],
    JObj = kz_json:set_values(Props, Doc),
    case kz_doc:account_db(JObj) =/= AccountDb
        orelse kz_doc:account_id(JObj) =/= AccountId
    of
        'false' -> JObj;
        'true' ->
            set_account(Account, JObj)
    end.

-spec set_account(kz_term:ne_binary(), kz_json:object()) -> kz_json:object().
set_account(Account, JObj) ->
    AccountDb = kzs_util:format_account_db(Account),
    Corrected =
        kz_json:set_values(
          [{<<"pvt_account_id">>, kzs_util:format_account_id(Account)}
          ,{<<"pvt_account_db">>, AccountDb}
          ], JObj),
    case kz_datamgr:save_doc(AccountDb, Corrected) of
        {'ok', Doc} -> Doc;
        {'error', _R} ->
            lager:error("failed to correct app"),
            Corrected
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec create_apps_store_doc(kz_term:ne_binary()) -> {'ok', kz_json:object()} | {'error', any()}.
create_apps_store_doc(Account) ->
    Doc = kzd_apps_store:new(Account),
    kz_datamgr:save_doc(kzs_util:format_account_db(Account), Doc).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec get_services_apps(kz_term:ne_binary()) -> kz_json:object().
get_services_apps(AccountId) ->
    ServicesApps = kz_services_applications:fetch(AccountId),
    case kz_term:is_not_empty(ServicesApps)
        orelse kz_services_reseller:is_reseller(AccountId)
    of
        'true' -> ServicesApps;
        'false' ->
            ResellerId = kz_services_reseller:get_id(AccountId),
            lager:debug("account ~s doesn't have apps in service plan, checking reseller ~s"
                       ,[AccountId, ResellerId]
                       ),
            kz_services_applications:fetch(ResellerId)
    end.

%%------------------------------------------------------------------------------
%% @doc Merge specific app document to app document while preserving where
%% attachments are coming from.
%% @end
%%------------------------------------------------------------------------------
-spec merge_attachment_wise(kz_json:object(), kz_json:object(), kz_json:key()) -> kz_json:object().
merge_attachment_wise(AppJObj, NewAppJObj, Type) ->
    merge_attachment_wise(AppJObj
                         ,NewAppJObj
                         ,Type
                         ,kz_doc:id(NewAppJObj)
                         ,kz_doc:account_db(NewAppJObj)
                         ,kz_doc:attachments(NewAppJObj)
                         ).

-spec merge_attachment_wise(kz_json:object(), kz_json:object(), kz_json:key()
                           ,kz_term:ne_binary(), kz_term:ne_binary(), kz_json:object()
                           ) -> kz_json:object().
merge_attachment_wise(AppJObj, NewAppJObj, Type, NewDocId, NewAccountDb, NewAttachments) ->
    Prop = [{[<<"pvt_app_attachments">>, Type, <<"_id">>], NewDocId}
           ,{[<<"pvt_app_attachments">>, Type, <<"pvt_account_db">>], NewAccountDb}
           ,{[<<"pvt_app_attachments">>, Type, <<"_attachments">>], NewAttachments}
           ],
    kz_json:set_values(Prop, kz_json:merge(AppJObj, kz_json:delete_keys(kz_doc:path_attachments(), NewAppJObj))).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec find_attachment(kz_json:object(), kz_term:api_ne_binary()) ->
          kz_either:either('not_found'
                          ,{AttachmentName::kz_term:ne_binary(), AttachmentsObject::kz_json:object()}
                          ).
find_attachment(_, 'undefined') ->
    {'error', 'not_found'};
find_attachment(JObj, AttachmentName) ->
    Paths = [[<<"pvt_app_attachments">>, <<"app_whitelabel">>]
            ,[<<"pvt_app_attachments">>, <<"service_plan">>]
            ,[<<"pvt_app_attachments">>, <<"master">>]
            ],
    find_attachment(JObj, AttachmentName, Paths).

-spec find_attachment(kz_json:object(), kz_term:api_ne_binary(), kz_json:paths()) ->
          kz_either:either('not_found'
                          ,{AttachmentName::kz_term:ne_binary(), AttachmentsObject::kz_json:object()}
                          ).
find_attachment(_, _, []) ->
    {'error', 'not_found'};
find_attachment(JObj, AttachmentName, [Path | Paths]) ->
    case kz_term:is_empty(kz_json:get_ne_json_value(Path ++ [<<"_attachments">>, AttachmentName], JObj)) of
        'true' ->
            find_attachment(JObj, AttachmentName, Paths);
        'false' ->
            {'ok', {AttachmentName
                   ,kz_json:get_json_value(Path, JObj)
                   }
            }
    end.



%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec app_whitelabel_doc_id(AppId::kz_term:ne_binary()) -> DocId::kz_term:ne_binary().
app_whitelabel_doc_id(AppId) ->
    <<"app_whitelabel-", AppId/binary>>.

-spec app_whitelabel_doc_id_to_app_id(AppWhitelabelId::kz_term:ne_binary()) -> AppId::kz_term:ne_binary().
app_whitelabel_doc_id_to_app_id(<<"app_whitelabel-", AppId/binary>>) ->
    AppId;
app_whitelabel_doc_id_to_app_id(Other) ->
    Other.
