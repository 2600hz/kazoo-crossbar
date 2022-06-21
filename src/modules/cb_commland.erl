%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2022, 2600Hz
%%% @doc Commland interaction
%%% @author Sean Wysor
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_commland).

-export([init/0
        ,authorize/1, authorize/2, authorize/3
        ,authenticate/1, authenticate/2, authenticate/3
        ,allowed_methods/0, allowed_methods/1
        ,resource_exists/0, resource_exists/1, resource_exists/2
        ,validate/1, validate/2
        ]).

-include("crossbar.hrl").


-define(DOT, <<".">>).
-define(COMPAT, <<"compatibility">>).
-define(COMPAT_NOUNS, [{<<"commland">>,[<<"compatibility">>]}]).
-define(COMMLAND_CONFIG_CAT, <<"commland">>).
-define(BASE_URL, kapps_config:get_ne_binary(?COMMLAND_CONFIG_CAT, <<"base_url">>, <<"https://packages.2600hz.com/commland/compatibility">>)).
-define(BASE_VERSION, kapps_config:get_ne_binary(?COMMLAND_CONFIG_CAT, <<"base_version">>, <<"5.1">>)).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.allowed_methods.commland">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.authorize.commland">>, ?MODULE, 'authorize'),
    _ = crossbar_bindings:bind(<<"*.authenticate.commland">>, ?MODULE, 'authenticate'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.commland">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.commland">>, ?MODULE, 'validate'),
    'ok'.


%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods() -> http_methods().
allowed_methods() -> [?HTTP_GET].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(?COMPAT) -> [?HTTP_GET].

-spec authorize(cb_context:context()) ->
          boolean() |
          {'stop', cb_context:context()}.
authorize(Context) ->
    authorize_commland(Context, cb_context:req_verb(Context), cb_context:req_nouns(Context)).

-spec authorize(cb_context:context(), path_token()) ->
          boolean() |
          {'stop', cb_context:context()}.
authorize(Context, _) ->
    authorize_commland(Context, cb_context:req_verb(Context), cb_context:req_nouns(Context)).

-spec authorize(cb_context:context(), path_token(), path_token()) ->
          boolean() |
          {'stop', cb_context:context()}.
authorize(Context, _, _) ->
    authorize_commland(Context, cb_context:req_verb(Context), cb_context:req_nouns(Context)).

-spec authorize_commland(cb_context:context(), http_method(), req_nouns()) ->
          boolean() |
          {'stop', cb_context:context()}.
authorize_commland(_, ?HTTP_GET, ?COMPAT_NOUNS) ->
    lager:debug("bypassing authorizing for request to compatibility url" ),
    'true';
authorize_commland(Context, _, [{<<"commland">>, _Nouns}]) ->
    {'stop', cb_context:add_system_error('forbidden', Context)};
authorize_commland(_, _Verb, _Nouns) ->
    'false'.

-spec authenticate(cb_context:context()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate(Context) ->
    authenticate_commland(Context, cb_context:req_verb(Context), cb_context:req_nouns(Context)).

-spec authenticate(cb_context:context(), path_token()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate(Context, _) ->
    authenticate_commland(Context, cb_context:req_verb(Context), cb_context:req_nouns(Context)).

-spec authenticate(cb_context:context(), path_token(), path_token()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate(Context, _, _) ->
    authenticate_commland(Context, cb_context:req_verb(Context), cb_context:req_nouns(Context)).

-spec authenticate_commland(cb_context:context(), http_method(), req_nouns()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate_commland(Context, ?HTTP_GET, ?COMPAT_NOUNS) ->
    {'true', Context};
authenticate_commland(_Context, _, _Nouns) ->
    'false'.

%%------------------------------------------------------------------------------
%% @doc This function determines if the provided list of Nouns are valid.
%% Failure here returns `404 Not Found'.
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_) -> 'true'.

-spec resource_exists(path_token(), path_token()) -> 'true'.
resource_exists(_,_) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc This function determines if the parameters and content are correct
%% for this request
%%
%% Failure here returns 400.
%% @end
%%------------------------------------------------------------------------------

-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_commland(cb_context:set_db_name(Context, ?KZ_WEBHOOKS_DB), cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, ?COMPAT) ->
    validate_commland(cb_context:set_db_name(Context, ?KZ_WEBHOOKS_DB), cb_context:req_verb(Context)).

-spec validate_commland(cb_context:context(), http_method()) -> cb_context:context().
validate_commland(Context, ?HTTP_GET) ->
    case cb_context:req_nouns(Context) of
        ?COMPAT_NOUNS -> compatibility_redirect(Context);
        _Nouns ->
            lager:debug("invalid request ~p", [_Nouns]),
            Context
    end.

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Display the current version of kazoo
%% @end
%%---------------------------`---------------------------------------------------
-spec compatibility_redirect(cb_context:context()) -> cb_context:context().
compatibility_redirect(Context) ->
    Url = get_redirect_url(),
    lager:debug("redirecting to upgrade url ~p", [Url]),
    crossbar_util:response_redirect(Context, Url, kz_json:from_list([{<<"url">>, Url}])).

-spec get_redirect_url() -> kz_term:ne_binary().
get_redirect_url() ->
    kz_binary:join([?BASE_URL, get_hashed_version()], <<"/">>).

-spec get_hashed_version() -> kz_term:ne_binary().
get_hashed_version() ->
    get_hashed_version(binary:split(?DOT, kapps_util:kazoo_version())).

-spec get_hashed_version(list()) -> kz_term:ne_binary().
get_hashed_version([Major, Minor|_]) ->
    lager:debug("compatible version found is ~s~s~s", [Major, ?DOT, Minor]),
    kz_binary:md5(kz_binary:join([Major, Minor], ?DOT));
get_hashed_version(_) ->
    lager:debug("no compatible version found using base ~s", [?BASE_VERSION]),
    kz_binary:md5(?BASE_VERSION).

