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
        ,authorize/1, authorize/2
        ,authenticate/1, authenticate/2, authenticate/3
        ,allowed_methods/0
        ,resource_exists/0
        ,validate/1
        ]).

-include("crossbar.hrl").


-define(DOT, <<".">>).
-define(BASE_URL, <<"https://packages.2600hz.com/commland/">>). %%should come from system config
-define(DEFAULT_VERSION, <<"5.1">>). %%should come from system config

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
    _ = crossbar_bindings:bind(<<"*.validate.commland">>, ?MODULE, 'validate').




%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods() -> http_methods().
allowed_methods() -> [?HTTP_GET].


%%------------------------------------------------------------------------------

%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec authorize(cb_context:context()) -> boolean() | {'stop', cb_context:context()}.
authorize(_Context) ->
    lager:debug("Breaker"),
    'true'.
-spec authorize(cb_context:context(), path_token()) -> boolean() | {'stop', cb_context:context()}.
authorize(_Context, _) ->
    lager:debug("Breaker breaker"),
    'true'.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%-----------------------------------------------------------------------------
-spec authenticate(cb_context:context()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate(Context) ->
    lager:debug("Breaker breaker 19"),
    {'true', Context}.

-spec authenticate(cb_context:context(), path_token()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate(Context, _) ->
    lager:debug("Breaker breaker 19i, come in"),
    {'true', Context}.

-spec authenticate(cb_context:context(), path_token(), path_token()) ->
          {'true', cb_context:context()} |
          'false'.
authenticate(Context, _, _) ->
    {'true', Context}.


%%------------------------------------------------------------------------------
%% @doc This function determines if the provided list of Nouns are valid.
%% Failure here returns `404 Not Found'.
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

%%------------------------------------------------------------------------------
%% @doc This function determines if the parameters and content are correct
%% for this request
%%
%% Failure here returns 400.
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    lager:debug("request is valid, processing"),
    redirect_request(Context).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Display the current version of kazoo
%% @end
%%---------------------------`---------------------------------------------------
-spec redirect_request(cb_context:context()) -> cb_context:context().
redirect_request(Context) ->
    lager:debug("request is valid, processing"),
    Url = get_redirect_url(),
    crossbar_util:redirect(Context, Url, kz_json:from_list([{<<"url">>, Url}])).

-spec get_redirect_url() -> kz_term:ne_binary().
get_redirect_url() ->
    kz_binary:join([?BASE_URL, get_hashed_version()], <<"/">>).

-spec get_hashed_version() -> kz_term:ne_binary().
get_hashed_version() ->
    get_hashed_version(kz_binary:split(?DOT, kapps_util:kazoo_version())).

get_hashed_version([Major, Minor|_]) ->
    kz_binary:md5(kz_binary:join([Major, Minor], ?DOT));
get_hashed_version(_) ->
    kz_binary:md5(?DEFAULT_VERSION).

