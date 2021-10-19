%%%-------------------------------------------------------------------
%%% @author Oscar Guerrero - oguerrero
%%% @copyright (C) 2011-2021, 2600Hz
%%% @doc Endpoints to create cluster, apps and the connection between them
%%%
%%% @end
%%% Created : 13. oct. 2021 01:59
%%%-------------------------------------------------------------------
-module(cb_appex_server).
-author("Oscar Guerrero").

%% API
-export([init/0
        ,authorize/2
        ,allowed_methods/1, allowed_methods/2
        ,resource_exists/1, resource_exists/2
        ,content_types_provided/2, content_types_provided/3
        ,validate/2, validate/3
        ,put/2
        ,post/1
        ,patch/1
        ,delete/1
        ]).

-include_lib("crossbar/src/crossbar.hrl").

-define(CLUSTER_PATH, <<"clusters">>).
-define(APP_PATH, <<"apps">>).
-define(OWNERSHIP_PATH, <<"ownerships">>).
-define(CB_CLUSTER, <<"clusters/listing_by_cluster_id">>).
-define(CB_APPS, <<"apps/listing_by_app_name">>).
-define(APPEX_DB_L, "app_exchange").
-define(APPEX_DB, <<?APPEX_DB_L>>).

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.authorize.appex_server">>, ?MODULE, 'authorize'),
    _ = crossbar_bindings:bind(<<"*.allowed_methods.appex_server">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.appex_server">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.appex_server">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.put.appex_server">>, ?MODULE, 'put'),
    _ = crossbar_bindings:bind(<<"*.execute.put.appex_server">>, ?MODULE, 'post'),
    _ = crossbar_bindings:bind(<<"*.execute.put.appex_server">>, ?MODULE, 'patch'),
    _ = crossbar_bindings:bind(<<"*.execute.put.appex_server">>, ?MODULE, 'get'),
    _ = crossbar_bindings:bind(<<"*.execute.put.appex_server">>, ?MODULE, 'delete').

%%------------------------------------------------------------------------------
%% @doc Authorizes the incoming request, returning true if the requestor is
%% allowed to access the resource, or false if not.
%% @end
%%------------------------------------------------------------------------------
-spec authorize(cb_context:context(), path_token()) -> boolean() | {'stop', cb_context:context()}.
authorize(Context, ?OWNERSHIP_PATH) ->
    authorize(Context
        ,cb_context:req_nouns(Context)
        ,cb_context:req_verb(Context)
    ).

-spec authorize(cb_context:context(),  path_token(), http_method()) -> boolean() | {'stop', cb_context:context()}.
authorize(Context, [{<<"appex_server">>, [?OWNERSHIP_PATH]}, _Account], ?HTTP_PUT) ->
    authorize_account(Context, cb_context:auth_account_id(Context));
authorize(Context, _Nouns, _Verb) ->
    {'stop', cb_context:add_system_error('forbidden', Context)}.

-spec authorize_account(cb_context:context(), kz_term:api_ne_binary()) -> boolean() | {'stop', cb_context:context()}.
authorize_account(Context, AuthId) ->
    validate_AuthId(Context
                   ,cb_context:is_account_admin(Context)
                   ,cb_context:is_superduper_admin(Context)
                   ,kz_services_reseller:is_reseller(AuthId)
                   ).

validate_AuthId(_Context, 'true', _IsSuperDuper, _IsReseller)  ->
    'true';
validate_AuthId(_Context, _IsAccAdmin, 'true', _IsReseller)  ->
    'true';
validate_AuthId(_Context, _IsAccAdmin, _IsSuperDuper, 'true')  ->
    'true';
validate_AuthId(Context, _IsAccAdmin, _IsSuperDuper, _IsReseller)  ->
    {'stop', cb_context:add_system_error('forbidden', Context)}.

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_) ->
    [?HTTP_PUT, ?HTTP_GET].

-spec allowed_methods(path_token(), path_token()) -> http_methods().
allowed_methods(_, _DocID) ->
    [?HTTP_GET, ?HTTP_PATCH, ?HTTP_POST, ?HTTP_DELETE].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists(path_token()) -> 'true'.
resource_exists(_) -> 'true'.

-spec resource_exists(path_token(), path_token()) -> 'true'.
resource_exists(_, _DocID) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Add content types accepted and provided by this module
%% @end
%%------------------------------------------------------------------------------
-spec content_types_provided(cb_context:context(), path_token()) -> cb_context:context().
content_types_provided(Context, _PathToken) ->
    Context.

-spec content_types_provided(cb_context:context(), path_token(), path_token()) -> cb_context:context().
content_types_provided(Context, _PathToken, _DocID) ->
    Context.

%%------------------------------------------------------------------------------
%% @doc This function determines if the parameters and content are correct
%% for this request
%%
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, PathToken) ->
    validate_request(Context, PathToken, cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token(), path_token()) -> cb_context:context().
validate(Context, PathToken, _DocID) ->
    validate_request(Context, PathToken, _DocID, cb_context:req_verb(Context)).

-spec validate_request(cb_context:context(), path_token(), req_verb()) -> cb_context:context().
validate_request(Context, ?CLUSTER_PATH, ?HTTP_PUT) ->
    cb_context:set_resp_status(validate_cluster_put_param(Context), 'success');
validate_request(Context, ?APP_PATH, ?HTTP_PUT) ->
    [AppName, AppVsn] = get_request_app_data(Context),
    cb_context:set_resp_status(validate_app_put_param(Context, AppName, AppVsn), 'success');
validate_request(Context, ?OWNERSHIP_PATH, ?HTTP_PUT) ->
    %%Working on it
    Context;

validate_request(Context, ?CLUSTER_PATH, ?HTTP_GET) ->
    case load_summary(?CLUSTER_PATH) of
        {'ok', Clusters} -> cb_context:set_resp_status(cb_context:set_resp_data(Context, Clusters), 'success');
        {'error', _E} ->  set_error_response(Context, <<"failed to list clusters by id">>)
    end;
validate_request(Context, ?APP_PATH, ?HTTP_GET) ->
    case load_summary(?APP_PATH) of
        {'ok', Clusters} -> cb_context:set_resp_status(cb_context:set_resp_data(Context, Clusters), 'success');
        {'error', _E} ->  set_error_response(Context, <<"failed to list apps by id">>)
    end.

-spec validate_request(cb_context:context(), path_token(), path_token(), req_verb()) -> cb_context:context().
validate_request(Context, ?CLUSTER_PATH, ClusterID, ?HTTP_GET) ->
    case kz_datamgr:open_cache_doc(?APPEX_DB, ClusterID) of
        {'ok', Cluster} -> cb_context:set_resp_status(cb_context:set_resp_data(Context, Cluster), 'success');
        {'error', _E} ->  set_error_response(Context, <<"failed to get cluster by id">>)
    end;
validate_request(Context, ?APP_PATH, AppID, ?HTTP_GET) ->
    case kz_datamgr:open_cache_doc(?APPEX_DB, AppID) of
        {'ok', Cluster} -> cb_context:set_resp_status(cb_context:set_resp_data(Context, Cluster), 'success');
        {'error', _E} ->  set_error_response(Context, <<"failed to get application by id">>)
    end.

-spec put(cb_context:context(), path_token()) -> cb_context:context().
put(Context, ?CLUSTER_PATH) ->
    Name = kz_json:get_ne_binary_value(<<"cluster_name">>, cb_context:req_data(Context)),
    validate_saved_cluster(appex_cluster_db:save_cluster(appexd_cluster:new(Name, cb_context:account_id(Context))), Context);
put(Context, ?APP_PATH) ->
    [AppName, AppVsn] = get_request_app_data(Context),
    AppId = kz_datamgr:get_uuid(),
    AppDoc = appexd_app:set_name(appexd_app:new(AppId, AppVsn)
                                ,AppName
                                ),
    validate_saved_app(appex_cluster_db:save_app(AppDoc), Context).

-spec patch(cb_context:context()) -> cb_context:context().
patch(Context) ->
    %%All code here
    Context.

-spec delete(cb_context:context()) -> cb_context:context().
delete(Context) ->
    %%All code here
    crossbar_doc:delete(Context).

-spec post(cb_context:context()) -> cb_context:context().
post(Context) ->
    %%All code here
    Context.

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_app_put_param(cb_context:context(), kz_term:ne_binary() | 'undefined', kz_term:ne_binary() | 'undefined') -> cb_context:context().
validate_app_put_param(Context, _AppName, 'undefined') ->
    set_error_response(Context, <<"no application name provided">>);
validate_app_put_param(Context, 'undefined', _AppVsn) ->
    set_error_response(Context, <<"no application version provided">>);
validate_app_put_param(Context, _AppName, _AppVsn) ->
    Context.

-spec validate_cluster_put_param(cb_context:context()) -> cb_context:context().
validate_cluster_put_param(Context) ->
    case kz_json:get_ne_binary_value(<<"cluster_name">>, cb_context:req_data(Context)) of
      'undefined' ->
          set_error_response(Context, <<"no cluster name provided">>);
      _ClusterName ->
          Context
    end.

-spec get_request_app_data(cb_context:context()) -> list().
get_request_app_data(Context) ->
    AppData = cb_context:req_data(Context),
    [kz_json:get_ne_binary_value(<<"app_name">>, AppData)
    ,kz_json:get_ne_binary_value(<<"app_version">>, AppData)
    ].

-spec validate_saved_cluster({'ok', kz_json:object()} | kz_datamgr:data_error(), cb_context:context()) -> cb_context:context().
validate_saved_cluster({'ok', ClusterDoc}, Context) ->
    cb_context:set_resp_status(cb_context:set_resp_data(Context, ClusterDoc), 'success');
validate_saved_cluster({'error', Error}, Context) ->
    cb_context:set_resp_status(cb_context:set_resp_data(Context, Error), 'error').

-spec validate_saved_app({'ok', kz_json:object()} | kz_datamgr:data_error(), cb_context:context()) -> cb_context:context().
validate_saved_app({'ok', AppDoc}, Context) ->
    cb_context:set_resp_status(cb_context:set_resp_data(Context, AppDoc), 'success');
validate_saved_app({'error', Error}, Context) ->
    cb_context:set_resp_status(cb_context:set_resp_data(Context, Error), 'error').

-spec load_summary(path_token()) -> cb_context:context().
load_summary(?CLUSTER_PATH) ->
    appex_cluster_db:list_clusters();
load_summary(?APP_PATH) ->
    appex_cluster_db:list_apps().

set_error_response(Context, ErrorMessage) ->
    cb_context:setters(Context
                      ,[{fun cb_context:set_resp_status/2, 'error'}
                       ,{fun cb_context:set_resp_data/2, ErrorMessage}]
                      ).

