%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @doc Manage system_auth scopes
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_scopes).

-include("crossbar.hrl").
-export([init/0
        ,authorize/1, authorize/2
        ,allowed_methods/0, allowed_methods/1
        ,resource_exists/0, resource_exists/1
        ,validate/1, validate/2
        ,post/2
        ,put/1
        ,delete/2

        ,maybe_deny_access/1
        ]).

-define(SCOPES_KEY, <<"scopes">>).
-define(SCHEMA, ?SCOPES_KEY).
-define(PVT_TYPE, <<"scope">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.authorize">>, ?MODULE, 'maybe_deny_access'),
    _ = crossbar_bindings:bind(<<"*.authorize.scopes">>, ?MODULE, 'authorize'),
    _ = crossbar_bindings:bind(<<"*.allowed_methods.scopes">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.scopes">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.scopes">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.put.scopes">>, ?MODULE, 'put'),
    _ = crossbar_bindings:bind(<<"*.execute.delete.scopes">>, ?MODULE, 'delete'),
    crossbar_bindings:bind(<<"*.execute.post.scopes">>, ?MODULE, 'post').

%%------------------------------------------------------------------------------
%% @doc Authorizes the incoming request, returning true if the requestor is
%% allowed to access the resource, or false if not.
%% @end
%%------------------------------------------------------------------------------
-spec authorize(cb_context:context()) -> boolean() | {'stop', cb_context:context()}.
authorize(Context) ->
    maybe_authorize(Context, cb_context:req_nouns(Context), cb_context:req_verb(Context)).

-spec authorize(cb_context:context(), path_token()) -> boolean() | {'stop', cb_context:context()}.
authorize(Context, _) ->
    maybe_authorize(Context, cb_context:req_nouns(Context), cb_context:req_verb(Context)).

maybe_authorize(Context, [{?SCOPES_KEY, _}|_], Method)
  when Method =:= ?HTTP_POST
       orelse Method =:= ?HTTP_PUT
       orelse Method =:= ?HTTP_DELETE ->
    case cb_context:is_superduper_admin(Context) of
        'true' -> 'true';
        'false' ->
            {'stop', cb_context:add_system_error('forbidden', Context)}
    end;
maybe_authorize(_, _, _) ->
    'false'.

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods() -> http_methods().
allowed_methods() ->
    [?HTTP_GET, ?HTTP_PUT].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_Scope) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_DELETE].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource.
%% For example:
%%
%% ```
%%    /scopes => []
%%    /scopes/foo => [<<"foo">>]
%%    /scopesfoo/bar => [<<"foo">>, <<"bar">>]
%% '''
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_Scope) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Check the request (request body, query string params, path tokens, etc)
%% and load necessary information.
%% /scopes might load a list of skel objects
%% /scopes/123 might load the skel object 123
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_scope(set_db_name(Context), cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, Scope) ->
    validate_scope(set_db_name(Context), Scope, cb_context:req_verb(Context)).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_scope(cb_context:context(), http_method()) -> cb_context:context().
validate_scope(Context, ?HTTP_GET) ->
    scope_summary(Context);
validate_scope(Context, ?HTTP_PUT) ->
    validate_request(Context).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_scope(cb_context:context(), path_token(), http_method()) -> cb_context:context().
validate_scope(Context, Scope, ?HTTP_DELETE) ->
    read(Context, Scope);
validate_scope(Context, Scope, ?HTTP_GET) ->
    read(Context, Scope);
validate_scope(Context, Scope, ?HTTP_POST) ->
    validate_request(Context, Scope).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_request(cb_context:context()) -> cb_context:context().
validate_request(Context) ->
    validate_request(Context, 'undefined').

-spec validate_request(cb_context:context(), api_path_token()) -> cb_context:context().
validate_request(Context, Scope) ->
    OnSuccess = fun(C) -> on_successful_validation(C, Scope) end,
    cb_context:validate_request_data(?SCHEMA, Context, OnSuccess).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec on_successful_validation(cb_context:context(), path_token()) -> cb_context:context().
on_successful_validation(Context, 'undefined') ->
    Doc = cb_context:doc(Context),
    ScopeId = kzd_scopes:id(Doc),
    ScopeDocId = kz_auth_scope:doc_id(ScopeId),
    case kz_datamgr:open_doc(?KZ_AUTH_DB, ScopeDocId) of
        {'ok', _} ->
            Error = kz_json:from_list([{<<"message">>, <<"scope id must be unique in system">>}
                                      ,{<<"cause">>, ScopeId}
                                      ]),
            cb_context:add_validation_error([<<"id">>], <<"unique">>, Error, Context);
        {'error', 'not_found'}->
            Setters = [{fun kz_doc:set_type/2, ?PVT_TYPE}
                      ,{fun kz_doc:set_id/2, ScopeDocId}
                      ],
            cb_context:set_doc(Context, kz_doc:setters(Doc, Setters));
        {'error', Error} ->
            crossbar_doc:handle_datamgr_errors(Error, ScopeId, Context)
    end;
on_successful_validation(Context, Scope) ->
    crossbar_doc:load_merge(Scope, Context, ?TYPE_CHECK_OPTION(?PVT_TYPE)).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _Scope) ->
    crossbar_doc:save(Context).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec put(cb_context:context()) -> cb_context:context().
put(Context) ->
    crossbar_doc:save(Context).

-spec delete(cb_context:context(), path_token()) -> cb_context:context().
delete(Context, _) ->
    crossbar_doc:delete(Context).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec read(cb_context:context(), path_token()) -> cb_context:context().
read(Context, Scope) ->
    crossbar_doc:load(Scope, Context, ?TYPE_CHECK_OPTION(?PVT_TYPE)).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec set_db_name(cb_context:context()) -> cb_context:context().
set_db_name(Context) ->
    cb_context:setters(Context
                      ,[{fun cb_context:set_db_name/2, ?KZ_AUTH_DB}
                       ,{fun cb_context:set_account_id/2, cb_context:auth_account_id(Context)}
                       ]).

%%------------------------------------------------------------------------------
%% @doc returns summary of system scope(s)
%% @end
%%------------------------------------------------------------------------------
-spec scope_summary(cb_context:context()) -> cb_context:context().
scope_summary(Context) ->
    Options = props:filter_undefined(
                [{'databases', [?KZ_AUTH_DB]}
                ,{'mapper', crossbar_view:get_doc_fun()}
                ,'include_docs'
                ]),
    crossbar_view:load(Context, <<"scopes/crossbar_listing">>, Options).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec maybe_deny_access(cb_context:context()) -> boolean() | {'stop', cb_context:context()}.
maybe_deny_access(Context) ->
    maybe_deny_access(Context, should_check_scopes(Context)).

%% @private
-spec maybe_deny_access(cb_context:context(), boolean()) -> boolean().
maybe_deny_access(_Context, 'false') ->
    'false';
maybe_deny_access(Context, 'true') ->
    Scopes = get_scopes(Context),
    Funs = [fun is_enforce_scopes_denies/3
           ,fun is_system_rules_denies/3
           ,fun is_reseller_rules_denies/3
           ,fun is_account_rules_denies/3
           ],
    maybe_deny_access(Funs, Context, Scopes, cb_context:path_tokens(Context)).

%% @private
-spec maybe_deny_access(fun(), cb_context:context(), map(), kz_term:ne_binaries()) ->
          boolean().
maybe_deny_access([], _, _, _) ->
    'false';
maybe_deny_access([Fun | Funs], Context, Scopes, ReqPath) ->
    case Fun(Context, Scopes, ReqPath) of
        'true' ->
            lager:info("denying access"),
            Cause = kz_json:from_list(
                      [{<<"cause">>, <<"access denied by scope restrictions">>}]
                     ),
            {'stop', cb_context:add_system_error('forbidden', Cause, Context)};
        'false' ->
            maybe_deny_access(Funs, Context, Scopes, ReqPath)
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec should_check_scopes(cb_context:context()) -> boolean().
should_check_scopes(Context) ->
    cb_context:is_authenticated(Context)
        andalso has_scopes(Context)
        andalso has_req_path(Context).

-spec has_scopes(cb_context:context()) -> boolean().
has_scopes(Context) ->
    AuthDoc = cb_context:auth_doc(Context),
    kz_term:is_not_empty(kz_json:get_ne_value(<<"scope">>, AuthDoc)).

-spec has_req_path(cb_context:context()) -> boolean().
has_req_path(Context) ->
    kz_term:is_not_empty(cb_context:path_tokens(Context)).

-spec get_scopes(cb_context:context()) -> map().
get_scopes(Context) ->
    JWTScopes = get_jwt_scopes(Context),
    Resolved = kz_term:uniq_list(
                 lists:flatten(
                   props:get_values(
                     kz_auth_scope:available_scopes(JWTScopes)
                    )
                  )
                ),
    #{jwt_scopes => JWTScopes
     ,resolved_scopes => Resolved
     ,required_scopes => get_required_scopes(Context)
     }.

-spec get_jwt_scopes(cb_context:context()) -> kz_term:ne_binaries().
get_jwt_scopes(Context) ->
    AuthDoc = cb_context:auth_doc(Context),
    Scopes = kz_json:get_ne_value(<<"scope">>, AuthDoc),
    kz_term:uniq_list(kz_auth_scope:split(Scopes)).

-spec get_required_scopes(cb_context:context()) -> kz_term:ne_binaries().
get_required_scopes(Context) ->
    TokenType = cb_context:auth_token_type(Context),
    lager:debug("token type is : ~p~n", [cb_context:auth_token_type(Context)]),
    get_required_scopes(Context, TokenType).

-spec get_required_scopes(cb_context:context(), atom()) -> kz_term:ne_binaries().
get_required_scopes(Context, 'x-auth-token') ->
    lager:debug("jwt token detected, enforcing scopes"),
    AuthScopes = crossbar_auth:auth_module_scopes(Context),

    [{Mod, _Params} | _] = cb_context:req_nouns(Context),
    Event = api_util:create_event_name(Context, <<"required_scopes.", Mod/binary>>),
    RequiredScopes = lists:flatten(crossbar_bindings:pmap(Event, Context)),
    kz_term:uniq_list(AuthScopes ++ RequiredScopes);
get_required_scopes(_, _TokenType) ->
    lager:debug("legacy token detected skipping scope enforcement"),
    [].

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec is_enforce_scopes_denies(cb_context:context(), map(), kz_term:binaries()) -> boolean().
is_enforce_scopes_denies(_, #{required_scopes := []}, _) ->
    'false';
is_enforce_scopes_denies(Context, #{required_scopes := RequiredScopes}, _) ->
    case kz_auth_scope:all(cb_context:auth_doc(Context), RequiredScopes) of
        'true' -> 'false';
        'false' -> 'true'
    end.

-spec is_system_rules_denies(cb_context:context(), map(), kz_term:binaries()) -> boolean().
is_system_rules_denies(Context, #{resolved_scopes := Resolved}, ReqPath) ->
    call_transport(Context, ReqPath, kz_auth_scope_rule:fetch_system(?APP_NAME, Resolved)).

-spec is_reseller_rules_denies(cb_context:context(), map(), kz_term:binaries()) -> boolean().
is_reseller_rules_denies(Context, #{resolved_scopes := Resolved}, ReqPath) ->
    AccountId = cb_context:auth_account_id(Context),
    call_transport(Context, ReqPath, kz_auth_scope_rule:fetch_reseller(?APP_NAME, AccountId, Resolved)).

-spec is_account_rules_denies(cb_context:context(), map(), kz_term:binaries()) -> boolean().
is_account_rules_denies(Context, #{resolved_scopes := Resolved}, ReqPath) ->
    AccountId = cb_context:auth_account_id(Context),
    call_transport(Context, ReqPath, kz_auth_scope_rule:fetch_account(?APP_NAME, AccountId, Resolved)).

-spec call_transport(cb_context:context(), kz_term:binaries(), kz_json:objects()) -> boolean().
call_transport(_, _, []) ->
    'false';
call_transport(Context, ReqPath, Rules) ->
    ReqVerb = cb_context:req_verb(Context),
    AuthDoc = cb_context:auth_doc(Context),
    kz_auth_transport_http:maybe_deny_access(AuthDoc, ReqPath, ReqVerb, Rules).
