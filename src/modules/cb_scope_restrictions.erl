%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @doc Manage scope restrictions
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_scope_restrictions).

-include("crossbar.hrl").
-export([init/0
        ,authorize/1, authorize/2
        ,allowed_methods/0, allowed_methods/1
        ,resource_exists/0, resource_exists/1
        ,validate/1, validate/2
        ,post/2
        ,put/1
        ,delete/2
        ]).

-define(SCOPE_RESTICTIONS_PATH, <<"scope_restictions">>).

-define(PVT_TYPE, <<"scope_restriction">>).
-define(SCHEMA, <<"scope_restrictions">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.allowed_methods.scope_restrictions">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.authorize.scope_restrictions">>, ?MODULE, 'authorize'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.scope_restrictions">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.scope_restrictions">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.put.scope_restrictions">>, ?MODULE, 'put'),
    _ = crossbar_bindings:bind(<<"*.execute.post.scope_restrictions">>, ?MODULE, 'post'),
    crossbar_bindings:bind(<<"*.execute.delete.scope_restrictions">>, ?MODULE, 'delete').

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

maybe_authorize(Context, [{?SCOPE_RESTICTIONS_PATH, _}], Method)
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
%%    /scope_restictions => []
%%    /scope_restictions/foo => [<<"foo">>]
%%    /scope_restictions/foo/bar => [<<"foo">>, <<"bar">>]
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
%% /scope_restictions might load a list of skel objects
%% /scope_restictions/123 might load the skel object 123
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_scope_restriction(set_context_db(Context), cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, Scope) ->
    validate_scope_restriction(set_context_db(Context), Scope, cb_context:req_verb(Context)).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_scope_restriction(cb_context:context(), http_method()) -> cb_context:context().
validate_scope_restriction(Context, ?HTTP_GET) ->
    scope_restriction_summary(Context);
validate_scope_restriction(Context, ?HTTP_PUT) ->
    validate_request(Context).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec validate_scope_restriction(cb_context:context(), path_token(), http_method()) -> cb_context:context().
validate_scope_restriction(Context, Scope, ?HTTP_DELETE) ->
    read(Context, Scope);
validate_scope_restriction(Context, Scope, ?HTTP_GET) ->
    read(Context, Scope);
validate_scope_restriction(Context, Scope, ?HTTP_POST) ->
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
-spec on_successful_validation(cb_context:context(), api_path_token()) -> cb_context:context().
on_successful_validation(Context, 'undefined') ->
    Doc = cb_context:doc(Context),
    DocId = kz_auth_scope:scope_rules_doc_id(kzd_scope_restrictions:scope_name(Doc)),
    Setters = [{fun kz_doc:set_id/2, DocId}
              ,{fun kz_doc:set_type/2, ?PVT_TYPE}
              ],
    cb_context:set_doc(Context, kz_doc:setters(Doc, Setters));
on_successful_validation(Context, Scope) ->
    DocId = kz_auth_scope:scope_rules_doc_id(Scope),
    crossbar_doc:load_merge(DocId, Context, ?TYPE_CHECK_OPTION(?PVT_TYPE)).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _ScopeRestriction) ->
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
    DocId = kz_auth_scope:scope_rules_doc_id(Scope),
    crossbar_doc:load(DocId, Context, ?TYPE_CHECK_OPTION(?PVT_TYPE)).

%%------------------------------------------------------------------------------
%% @doc returns summary of scope restrictions
%% @end
%%------------------------------------------------------------------------------
-spec scope_restriction_summary(cb_context:context()) -> cb_context:context().
scope_restriction_summary(Context) ->
    Options = [{'doc_type', ?PVT_TYPE}
              ,{'mapper', crossbar_view:get_doc_fun()}
              ,'include_docs'
              ],
    Selector = [{'start', [{<<"doc_type">>, ?PVT_TYPE}]}
               ,{'end', [{<<"doc_type">>, ?PVT_TYPE}]}
               ],
    crossbar_view:find(Context, <<"crossbar_listings/by_type_id">>, Selector, Options).

set_context_db(Context) ->
    set_context_db(Context, cb_context:account_id(Context)).

set_context_db(Context, 'undefined') ->
    cb_context:set_db_name(Context, ?KZ_AUTH_DB);
set_context_db(Context, AccountId) ->
    cb_context:set_db_name(Context, AccountId).
