%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @author Kevin
%%% @doc Endpoint for getstream
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_getstream).

-export([init/0
        ,allowed_methods/1
        ,resource_exists/1
        ,validate/2
        ,content_types_provided/2
        ,put/2
        ]).

-include_lib("crossbar/src/crossbar.hrl").

-define(TOKEN_PATH, <<"token">>).
-define(ALG, <<"HS256">>).
-define(ISSUER, <<"kazoo">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.allowed_methods.getstream">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.getstream">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.getstream">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.put.getstream">>, ?MODULE, 'put').

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(?TOKEN_PATH) ->
    [?HTTP_PUT].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists(path_token()) -> 'true'.
resource_exists(?TOKEN_PATH) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Add content types accepted and provided by this module
%% @end
%%------------------------------------------------------------------------------
-spec content_types_provided(cb_context:context(), path_token()) -> cb_context:context().
content_types_provided(Context, _) ->
    Context.

%%------------------------------------------------------------------------------
%% @doc This function determines if the parameters and content are correct
%% for this request
%%
%% Failure here returns 400.
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, ?TOKEN_PATH) ->
    [UserId] = props:get_value(<<"users">>, cb_context:req_nouns(Context)),
    validate_request(Context, ?TOKEN_PATH, UserId, cb_context:req_verb(Context)).

-spec validate_request(cb_context:context(), path_token(), list(), req_verb()) -> cb_context:context().
validate_request(Context, ?TOKEN_PATH, UserId, ?HTTP_PUT) ->
    Context1 = crossbar_doc:load(UserId, Context),
    case cb_context:resp_status(Context1) of
        'success' -> validate_secret(Context1);
        _Else -> Context1
    end.

-spec validate_secret(cb_context:context()) -> cb_context:context().
validate_secret(Context) ->
    case maybe_get_secret(Context) of
        'undefined' ->
            cb_context:add_system_error('datastore_missing', Context);
        Secret ->
            cb_context:set_resp_status(cb_context:store(Context, 'getstream_secret', Secret), 'success')
    end.

-spec put(cb_context:context(), path_token()) -> cb_context:context().
put(Context, ?TOKEN_PATH) ->
    UserData = cb_context:doc(Context),
    UserId = kz_json:get_first_defined([[<<"getstream">>, <<"user_id">>],<<"username">>],UserData),
    Secret = cb_context:fetch(Context, 'getstream_secret'),
    TokenId = kz_datamgr:get_uuid(),
    {_, Token} = kz_auth_jwt:encode(
                   #{claims => [{<<"user_id">>, UserId}],
                     issuer => ?ISSUER,
                     alg => ?ALG,
                     key => Secret}
                  ),

    Setters = [{fun cb_context:set_resp_status/2, 'success'}
              ,{fun cb_context:set_resp_data/2,kz_json:from_list([{<<"id">>, TokenId}, {<<"token">>, Token}])}],

    cb_context:set_resp_status(cb_context:setters(Context, Setters), 'success').

-spec maybe_get_secret(cb_context:context()) -> kz_term:api_binary().
maybe_get_secret(Context) ->
    Routines = [fun maybe_get_account_secret/1
               ,fun maybe_get_reseller_secret/1
               ,fun maybe_get_default_secret/1
               ],
    lists:foldl(fun(Routine, 'undefined') ->
                        Routine(Context);
                   (_Routine, Secret) ->
                        Secret
                end, 'undefined', Routines).

-spec maybe_get_account_secret(cb_context:context()) -> kz_term:api_binary().
maybe_get_account_secret(Context) ->
    AccountId = cb_context:account_id(Context),
    case kzd_accounts:fetch(AccountId) of
        {'ok', JObj} ->
            kz_json:get_ne_binaries([<<"getstream">>, <<"secret">>], JObj);
        {'error', _R} ->
            lager:debug("unable to get account document ~s: ~p", [AccountId, _R]),
            'undefined'
    end.

-spec maybe_get_reseller_secret(cb_context:context()) -> kz_term:api_binary().
maybe_get_reseller_secret(Context) ->
    ResellerId = cb_context:reseller_id(Context),
    case kzd_accounts:fetch(ResellerId) of
        {'ok', JObj} -> kz_json:get_ne_binaries([<<"getstream">>, <<"secret">>], JObj);
        {'error', _R} ->
            lager:debug("unable to get reseller document ~s: ~p", [ResellerId, _R]),
            'undefined'
    end.

-spec maybe_get_default_secret(cb_context:context()) -> kz_term:api_binary().
maybe_get_default_secret(_Context) ->
    kapps_config:get_ne_binary(<<(?CONFIG_CAT)/binary, ".getstream">>, <<"secret">>).
