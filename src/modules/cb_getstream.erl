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

-define(CONNECT_PATH, <<"connect">>).
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
allowed_methods(?CONNECT_PATH) ->
    [?HTTP_PUT].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists(path_token()) -> 'true'.
resource_exists(?CONNECT_PATH) -> 'true'.

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
validate(Context, ?CONNECT_PATH) ->
    [UserId] = props:get_value(<<"users">>, cb_context:req_nouns(Context)),
    validate_request(Context, ?CONNECT_PATH, UserId, cb_context:req_verb(Context)).

-spec validate_request(cb_context:context(), path_token(), list(), req_verb()) -> cb_context:context().
validate_request(Context, ?CONNECT_PATH, UserId, ?HTTP_PUT) ->
    Context1 = crossbar_doc:load(UserId, Context),
    case cb_context:resp_status(Context1) of
        'success' -> Context2 = validate_secret(Context1),
                     validate_api_key(Context2);
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

-spec validate_api_key(cb_context:context()) -> cb_context:context().
validate_api_key(Context) ->
    case maybe_get_api_key(Context) of
        'undefined' ->
            cb_context:add_system_error('datastore_missing', Context);
        ApiKey ->
            cb_context:set_resp_status(cb_context:store(Context, 'getstream_api_key', ApiKey), 'success')
    end.

-spec put(cb_context:context(), path_token()) -> cb_context:context().
put(Context, ?CONNECT_PATH) ->
    UserData = cb_context:doc(Context),
    UserId = kz_json:get_first_defined([[<<"getstream">>, <<"user_id">>], <<"_id">>],UserData),
    Secret = cb_context:fetch(Context, 'getstream_secret'),
    ApiKey = cb_context:fetch(Context, 'getstream_api_key'),

    case validate_if_user_exist_on_getstream(UserId, Context, Secret, ApiKey, UserData) of
        'false' ->
            cb_context:set_resp_status(Context, 'error');
        'true' ->
            TokenId = kz_datamgr:get_uuid(),

            {_, Token} = create_token_for_getstream('body', UserId, Secret),

            Setters = [{fun cb_context:set_resp_status/2, 'success'}
                      ,{fun cb_context:set_resp_data/2
                       ,kz_json:from_list([{<<"id">>, TokenId}
                                          ,{<<"token">>, Token}
                                          ,{<<"api_key">>, ApiKey}
                                          ])
                       }
                      ],

            cb_context:set_resp_status(cb_context:setters(Context, Setters), 'success')

    end.

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

-spec maybe_get_api_key(cb_context:context()) -> kz_term:api_binary().
maybe_get_api_key(Context) ->
    Routines = [fun maybe_get_account_api_key/1
               ,fun maybe_get_reseller_api_key/1
               ,fun maybe_get_default_api_key/1
               ],
    lists:foldl(fun(Routine, 'undefined') ->
                        Routine(Context);
                   (_Routine, ApiKey) ->
                        ApiKey
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

-spec maybe_get_account_api_key(cb_context:context()) -> kz_term:api_binary().
maybe_get_account_api_key(Context) ->
    AccountId = cb_context:account_id(Context),
    case kzd_accounts:fetch(AccountId) of
        {'ok', JObj} ->
            kz_json:get_ne_binaries([<<"getstream">>, <<"api_key">>], JObj);
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

-spec maybe_get_reseller_api_key(cb_context:context()) -> kz_term:api_binary().
maybe_get_reseller_api_key(Context) ->
    ResellerId = cb_context:reseller_id(Context),
    case kzd_accounts:fetch(ResellerId) of
        {'ok', JObj} -> kz_json:get_ne_binaries([<<"getstream">>, <<"api_key">>], JObj);
        {'error', _R} ->
            lager:debug("unable to get reseller document ~s: ~p", [ResellerId, _R]),
            'undefined'
    end.

-spec maybe_get_default_secret(cb_context:context()) -> kz_term:api_binary().
maybe_get_default_secret(_Context) ->
    kapps_config:get_ne_binary(<<(?CONFIG_CAT)/binary, ".getstream">>, <<"secret">>).

-spec maybe_get_default_api_key(cb_context:context()) -> kz_term:api_binary().
maybe_get_default_api_key(_Context) ->
    kapps_config:get_ne_binary(<<(?CONFIG_CAT)/binary, ".getstream">>, <<"api_key">>).

-spec validate_if_user_exist_on_getstream(kz_term:api_binary(), cb_context:context(), kz_term:api_binary(), kz_term:api_ne_binary(), kz_json:api_json_term()) -> boolean().
validate_if_user_exist_on_getstream(UserId, Context, Secret, APIKey, UserData) ->
    {_, TokenHeader} = create_token_for_getstream('header' ,<<"read">>, Secret),

    Headers = create_headers(TokenHeader),

    Eq = kz_json:from_list([{<<"$eq">>,UserId}]),
    Id = kz_json:from_list([{<<"id">>, Eq}]),
    Params = kz_json:from_list([{<<"filter_conditions">>, Id}]),
    JsParams = kz_json:encode(Params),

    QS = [{<<"api_key">>, APIKey}
         ,{<<"payload">>, kz_http_util:urlencode(JsParams)}
         ],

    URL = create_getstream_url(<<"users">>, QS),

    lager:warning("URL: ~p",[URL]),

    case kz_http:get(URL, Headers) of
        {'ok', _Code, _RespHeaders, RespBody} ->
            RespDecoded = kz_json:decode(RespBody),
            check_getstream_body(kz_json:get_list_value(<<"users">>, RespDecoded), UserId, Context, APIKey, Secret, UserData);
        _E ->
            lager:debug("failed: ~p", [_E]),
            'false'
    end.

-spec create_getstream_url(kz_term:ne_binary(), kz_term:protardplist()) -> kz_http:url().
create_getstream_url(Resource, QS) ->
    BaseUrl = <<"https://chat.stream-io-api.com">>,
    iolist_to_binary([BaseUrl, "/", Resource, "?", kz_http_util:props_to_querystring(QS)]).

-spec check_getstream_body(kz_term:api_list(), kz_term:api_binary(), cb_context:context(), kz_term:api_ne_binary(), kz_term:api_binary(), kz_json:api_json_term()) -> boolean().
check_getstream_body([], UserId, Context, APIKey, Secret, UserData) ->
    create_getstream_user(UserId, Context, APIKey, Secret, UserData);
check_getstream_body(_User, _UserId, _Context, _APIKey, _Secret, _UserData) ->
    'true'.

-spec create_getstream_user(kz_term:api_binary(), cb_context:context(), kz_term:api_ne_binary(), kz_term:api_binary(), kz_json:api_json_term()) -> boolean().
create_getstream_user(UserId, Context, APIKey, Secret, UserData)->
    QS = [{<<"api_key">>, APIKey}],
    URL = create_getstream_url(<<"users">>, QS),

    {_, TokenHeader} = create_token_for_getstream('header', <<"write">>, Secret),

    Headers = create_headers(TokenHeader),

    FirstName = kz_json:get_first_defined([[<<"getstream">>, <<"user_id">>],<<"first_name">>],UserData),
    LastName = kz_json:get_first_defined([[<<"getstream">>, <<"user_id">>],<<"last_name">>],UserData),

    Body = kz_json:from_list(
             [{<<"id">>, UserId},
              {<<"teams">>, [cb_context:account_id(Context)]},
              {<<"username">>, kz_json:get_first_defined([[<<"getstream">>, <<"user_id">>], <<"username">>], UserData)},
              {<<"name">>, <<FirstName/binary, LastName/binary>>},
              {<<"role">>, kz_json:get_first_defined([[<<"getstream">>, <<"user_id">>], <<"priv_level">>], UserData)}
             ]),

    Account = kz_json:from_list([{UserId, Body}]),
    Params = kz_json:from_list([{<<"users">>, Account}]),
    JsParams = kz_json:encode(Params),

    case kz_http:post(URL, Headers, JsParams) of
        {'ok', 201, _RespHeaders, RespBody} ->
            lager:debug("user created: ~p",[RespBody]),
            'true';
        {'error', _E} ->
            lager:debug("failed: ~p", [_E]),
            'false'
    end.

-spec create_token_for_getstream(atom(), kz_term:api_binary(), kz_term:api_binary()) ->
          {'ok', kz_term:ne_binary()} |
          {'error', any()}.
create_token_for_getstream('header', Value, Secret) ->
    kz_auth_jwt:encode(
      #{claims => [{<<"resource">>, <<"users">>}
                  ,{<<"action">>, Value}
                  ,{<<"feed_id">>, <<"*">>}
                  ]
       ,issuer => ?ISSUER
       ,alg => ?ALG
       ,key => Secret
       });
create_token_for_getstream(_Type, Value, Secret) ->
    kz_auth_jwt:encode(
      #{claims => [{<<"user_id">>, Value}]
       ,issuer => ?ISSUER
       ,alg => ?ALG
       ,key => Secret
       }).

-spec create_headers(kz_term:ne_binary()) -> kz_http:headers().
create_headers(TokenHeader) ->
    props:filter_undefined(
      [{"Stream-Auth-Type", "jwt"}
      ,{"Authorization", TokenHeader}
      ,{"te", "trailers"}
      ]).
