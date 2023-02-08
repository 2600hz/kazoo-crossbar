%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2023, 2600Hz
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

-export([chat_getstream_enabled/1, chat_getstream_enabled/2, set_chat_getstream_enabled/2]).

-include_lib("crossbar/src/crossbar.hrl").

-define(CONNECT_PATH, <<"connect">>).
-define(ALG, <<"HS256">>).
-define(ISSUER, <<"kazoo">>).

-type doc() :: kz_json:object().
-type docs() :: [doc()].
-export_type([doc/0, docs/0]).

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
    validate_user_feature(Context, ?CONNECT_PATH, UserId, cb_context:req_verb(Context)).

-spec validate_user_feature(cb_context:context(), path_token(), list(), req_verb()) -> cb_context:context().
validate_user_feature(Context, ?CONNECT_PATH, UserId, ?HTTP_PUT) ->
    Context1 = crossbar_doc:load(UserId, Context),
    Enabled = chat_getstream_enabled(cb_context:doc(Context1), 'false'),
    case Enabled of
        'true' -> validate_request(Context1, ?CONNECT_PATH, ?HTTP_PUT);
        _Else ->
            lager:debug("feature is not available for the user: ~p", [UserId]),
            cb_context:add_system_error(400, 'disabled', <<"Feature disabled">>, Context1)
    end.

-spec validate_request(cb_context:context(), path_token(), req_verb()) -> cb_context:context().
validate_request(Context, ?CONNECT_PATH, ?HTTP_PUT) ->
    case cb_context:resp_status(Context) of
        'success' -> Context1 = validate_secret(Context),
                     validate_api_key(Context1);
        _Else -> Context
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
    ApiKey = cb_context:fetch(Context, 'getstream_api_key'),

    case create_or_update_user_on_getstream(Context) of
        'false' ->
            ErrMsg = <<"something went wrong during communication with getstream">>,
            cb_context:add_system_error(503, <<"service_unavailable">>, ErrMsg, Context);
        'true' ->
            TokenId = kz_datamgr:get_uuid(),

            Token = create_getstream_jwt_token(Context),

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

-spec create_or_update_user_on_getstream(cb_context:context()) -> boolean().
create_or_update_user_on_getstream(Context) ->
    case get_getstream_user(Context) of
        {'ok', GetStreamUsers} ->
            create_or_update_user_on_getstream(Context, GetStreamUsers);
        {'error', _E} ->
            lager:debug("failed to get getstream user: ~p", [_E]),
            'false'
    end.

-spec create_or_update_user_on_getstream(cb_context:context(), kz_json:objects()) -> boolean().
create_or_update_user_on_getstream(Context, []) ->
    create_getstream_user(Context);
create_or_update_user_on_getstream(Context, [GetStreamUser]) ->
    maybe_update_getstream_user(Context, GetStreamUser).

maybe_update_getstream_user(Context, GetStreamUser) ->
    case diff_current_info(Context, GetStreamUser) of
        [] ->
            %% the data is valid and no update is required, continue with jwt token generation
            'true';
        UpdatedValues ->
            update_getstream_user(Context, UpdatedValues)
    end.

diff_current_info(Context, GetStreamUser) ->
    CurrentGetStreamInfo = kz_json:from_list(getstream_user_info(Context)),

    lists:filtermap(fun({Key, CurrentValue}) ->
                            case kz_json:get_ne_binary_value(Key, CurrentGetStreamInfo) of
                                CurrentValue -> 'false';
                                NewValue -> {'true', {Key, NewValue}}
                            end
                    end
                   ,[{<<"role">>, kz_json:get_ne_binary_value(<<"role">>, GetStreamUser)}
                    ,{<<"username">>, kz_json:get_ne_binary_value(<<"username">>, GetStreamUser)}
                    ,{<<"name">>, kz_json:get_ne_binary_value(<<"name">>, GetStreamUser)}
                    ]
                   ).

-spec get_getstream_user(cb_context:context()) -> kz_either:either(any(), kz_json:objects()).
get_getstream_user(Context) ->
    UserId = kz_doc:id(cb_context:doc(Context)),

    Payload = kz_json:from_list(
                [{<<"filter_conditions">>
                 ,kz_json:from_list(
                    [{<<"id">>, kz_json:from_list([{<<"$eq">>, UserId}])}])
                 }
                ]
               ),
    QS = [{<<"payload">>, kz_http_util:urlencode(kz_json:encode(Payload))}],
    URL = build_url(Context, QS),
    Headers = create_headers(Context, <<"read">>),

    case kz_http:get(URL, Headers) of
        {'ok', _Code, _RespHeaders, RespBody} ->
            RespDecoded = kz_json:decode(RespBody),
            {'ok', kz_json:get_list_value(<<"users">>, RespDecoded, [])};
        {'error', _}=Error ->
            Error
    end.

-spec create_getstream_user(cb_context:context()) -> boolean().
create_getstream_user(Context)->
    UserDoc = cb_context:doc(Context),
    UserId = kz_doc:id(UserDoc),

    User = kz_json:from_list(getstream_user_info(Context)),
    Body = kz_json:from_list([{<<"users">>
                              ,kz_json:from_list([{UserId, User}])
                              }
                             ]
                            ),
    ReqBody = kz_json:encode(Body),

    URL = build_url(Context, []),
    Headers = create_headers(Context, <<"write">>),

    case kz_http:post(URL, Headers, ReqBody) of
        {'ok', 201, _RespHeaders, _RespBody} ->
            'true';
        {'error', _E} ->
            lager:debug("failed to create getstream user: ~p", [_E]),
            'false'
    end.

-spec update_getstream_user(cb_context:context(), kz_term:proplist()) -> boolean().
update_getstream_user(Context, UpdatedValues)->
    UserDoc = cb_context:doc(Context),
    UserId = kz_doc:id(UserDoc),

    UserProperties = kz_json:from_list(
                       [{<<"id">>, UserId}
                       ,{<<"set">>, kz_json:from_list(UpdatedValues)}
                       ]
                      ),

    Params = kz_json:from_list([{<<"users">>, [UserProperties]}]),
    ReqBody = kz_json:encode(Params),

    URL = build_url(Context, []),
    Headers = create_headers(Context, <<"write">>),

    case kz_http:patch(URL, Headers, ReqBody) of
        {'ok', 200, _RespHeaders, _RespBody} ->
            'true';
        {'error', _E} ->
            lager:debug("failed to update getstream user: ~p", [_E]),
            'false'
    end.

-spec getstream_user_info(cb_context:context()) -> kz_term:proplist().
getstream_user_info(Context) ->
    UserDoc = cb_context:doc(Context),
    FirstName = kz_json:get_ne_binary_value([<<"getstream">>, <<"first_name">>]
                                           ,UserDoc
                                           ,kzd_users:first_name(UserDoc)
                                           ),
    LastName = kz_json:get_ne_binary_value([<<"getstream">>, <<"last_name">>]
                                          ,UserDoc
                                          ,kzd_users:last_name(UserDoc)
                                          ),
    Username = kz_json:get_ne_binary_value([<<"getstream">>, <<"username">>]
                                          ,UserDoc
                                          ,kzd_users:username(UserDoc)
                                          ),
    UserRole = kz_json:get_ne_binary_value([<<"getstream">>, <<"priv_level">>]
                                          ,UserDoc
                                          ,kzd_users:priv_level(UserDoc)
                                          ),
    [{<<"id">>, kz_doc:id(UserDoc)}
    ,{<<"teams">>, [cb_context:account_id(Context)]}
    ,{<<"username">>, Username}
    ,{<<"name">>, <<FirstName/binary, LastName/binary>>}
    ,{<<"role">>, UserRole}
    ].

-spec create_getstream_jwt_token(cb_context:context()) -> kz_term:ne_binary().
create_getstream_jwt_token(Context) ->
    UserDoc = cb_context:doc(Context),
    UserId = kz_doc:id(UserDoc),

    Secret = cb_context:fetch(Context, 'getstream_secret'),
    {'ok', Token} = kz_auth_jwt:encode(
                      #{claims => [{<<"user_id">>, UserId}]
                       ,issuer => ?ISSUER
                       ,alg => ?ALG
                       ,key => Secret
                       }),
    Token.

-spec create_headers(cb_context:context(), kz_term:ne_binary()) -> kz_http:headers().
create_headers(Context, Action) ->
    Secret = cb_context:fetch(Context, 'getstream_secret'),
    {'ok', TokenHeader} = kz_auth_jwt:encode(
                            #{claims => [{<<"resource">>, <<"users">>}
                                        ,{<<"action">>, Action}
                                        ,{<<"feed_id">>, <<"*">>}
                                        ]
                             ,issuer => ?ISSUER
                             ,alg => ?ALG
                             ,key => Secret
                             }),

    props:filter_undefined(
      [{"Stream-Auth-Type", "jwt"}
      ,{"Authorization", TokenHeader}
      ,{"te", "trailers"}
      ]).

-spec build_url(cb_context:context(), kz_term:proplist()) -> kz_http:url().
build_url(Context, QS) ->
    BaseUrl = <<"https://chat.stream-io-api.com">>,
    NewQS = props:set_value(<<"api_key">>, cb_context:fetch(Context, 'getstream_api_key'), QS),
    kz_term:to_binary(
      [BaseUrl
      ,"/users"
      ,"?"
      ,kz_http_util:props_to_querystring(NewQS)
      ]
     ).

%%------------------------------------------------------------------------------
%% @doc Accessor functions for the getstream
%% @end
%%------------------------------------------------------------------------------
-spec chat_getstream_enabled(doc()) -> boolean().
chat_getstream_enabled(Doc) ->
    chat_getstream_enabled(Doc, 'false').

-spec chat_getstream_enabled(doc(), Default) -> boolean() | Default.
chat_getstream_enabled(Doc, Default) ->
    kz_json:get_boolean_value([<<"pvt_chat">>, <<"getstream">>, <<"enabled">>], Doc, Default).

-spec set_chat_getstream_enabled(doc(), boolean()) -> doc().
set_chat_getstream_enabled(Doc, ChatGetstreamEnabled) ->
    kz_json:set_value([<<"pvt_chat">>, <<"getstream">>, <<"enabled">>], ChatGetstreamEnabled, Doc).