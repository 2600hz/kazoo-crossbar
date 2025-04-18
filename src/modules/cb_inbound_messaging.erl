%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2025, 2600Hz
%%% @doc Messages module for both sms and mms
%%% @author Sylvia Deal
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_inbound_messaging).

-export([init/0
        ,requires_envelope/2
        ,request_data/2
        ,authenticate/2, authorize/2
        ,allowed_methods/1
        ,resource_exists/1
        ,validate/2
        ,put/2
        ]).

-include_lib("crossbar/src/crossbar.hrl").

-define(TRUNKING_IO, <<"trunkingio">>).


%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.

init() ->
    _ = crossbar_bindings:bind(<<"*.requires_envelope.inbound_messaging">>, ?MODULE, 'requires_envelope'),
    _ = crossbar_bindings:bind(<<"*.request_data.post.inbound_messaging">>, ?MODULE, 'request_data'),
    _ = crossbar_bindings:bind(<<"*.allowed_methods.inbound_messaging">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.inbound_messaging">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.inbound_messaging">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.post.inbound_messaging">>, ?MODULE, 'put'),
    _ = crossbar_bindings:bind(<<"*.authenticate.inbound_messaging">>, ?MODULE, 'authenticate'),
    _ = crossbar_bindings:bind(<<"*.authorize.inbound_messaging">>, ?MODULE, 'authorize'),
    crossbar_bindings:bind(<<"*.execute.delete.inbound_messaging">>, ?MODULE, 'delete').


-spec requires_envelope(cb_context:context(), path_token()) -> boolean().
requires_envelope(_,_) -> 'false'.

%%------------------------------------------------------------------------------
%% @doc Requests from TrunkingIO include null keys, which crossbar_util
%% implicitly filters out when using kz_json:set_keys(). HMAC auth requires
%% the payload as sent, including null kvs.
%% Note that req_data and req_json are set differently-- req_data is
%% the full unmodified original request, req_json is set with the usual
%% key normalization.
%% @end
%%------------------------------------------------------------------------------
-spec request_data(cb_context:context(), path_token()) -> {'ok', cb_context:context()} |
          {'error', any()}.
request_data({Req, Context, _CT, QS}, _Carrier) ->
    case get_request_json(api_util:get_request_body(Req)) of
        {ok, Body} ->
            Ctx = set_data_in_context(Context, Body, QS),
            {ok, Ctx};
        {error, _} -> {error, parse_error}
    end.

get_request_json({ok, Body, _}) ->
    decode_req_json(Body);
get_request_json({error, _, _}) ->  {error, parse_error}.

-spec decode_req_json(binary()) -> {ok, kz_json:object()} | {'error', 'parse_error'}.
decode_req_json(Body) ->
    try kz_json:unsafe_decode(Body) of
        JObj ->
            lager:debug("request has a json payload: ~ts", [kz_log:redactor(Body)]),
            {ok, JObj}
    catch
        'throw':{'invalid_json',{'error',{ErrLine, ErrMsg}}, _JSON} ->
            lager:debug("failed to decode json near ~p: ~s", [ErrLine, ErrMsg]),
            {'error', 'parse_error'};
        _E:_R ->
            lager:debug("unknown catch from json decode ~p : ~p", [_E, _R]),
            {error, parse_error}
    end.

-spec normalize_data_keys(kz_json:object()) -> kz_json:object().
normalize_data_keys(JObj) ->
    kz_json:foldl(fun normalize_data_keys_foldl/3, kz_json:new(), JObj).

-spec normalize_data_keys_foldl(kz_json:key(), kz_json:json_term(), kz_json:object()) -> kz_json:object().
normalize_data_keys_foldl(K, V, JObj) -> kz_json:set_value(kz_json:normalize_key(K), V, JObj).

set_data_in_context(Context, JObj, QS) ->
    DataJObj = normalize_data_keys(JObj), % So req_data can be used normally. Otherwise, 'null' values give <<"null">> not 'undefined', as typically expected
    Setters = [{fun cb_context:set_req_json/2, JObj}
              ,{fun cb_context:set_req_data/2, DataJObj}
              ,{fun cb_context:set_query_string/2, QS}
              ],
    cb_context:setters(Context, Setters).

%%------------------------------------------------------------------------------
%% @doc Authenticates the incoming request, returning true if the requestor is
%% known, or false if not.
%% @end
%%------------------------------------------------------------------------------
-spec authenticate(cb_context:context(), path_token()) -> boolean().
authenticate(Context, Carrier) ->
    Payload = cb_context:req_json(Context),
    KzdCarrier = binary_to_atom(<<"knm_", Carrier/binary>>),
    case kz_module:is_exported(KzdCarrier, 'authenticate_req', 3) of
        true ->
            KzdCarrier:authenticate_req(Payload, cb_context:req_headers(Context), cb_context:account_id(Context));
        _ -> false
    end.

-spec authorize(cb_context:context(), path_token()) -> boolean().
authorize(_, _) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_Carrier) ->
    [?HTTP_POST].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource.
%% For example:
%%
%% ```
%%    /skels => []
%%    /skels/foo => [<<"foo">>]
%%    /skels/foo/bar => [<<"foo">>, <<"bar">>]
%% '''
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists(path_token()) -> boolean().
resource_exists(?TRUNKING_IO) ->
    kz_module:ensure_loaded(knm_trunkingio) =/= false
        andalso kz_module:ensure_loaded(kzd_trunkingio_im) =/= false;
resource_exists(_) -> false.

-spec put(cb_context:context(), path_token()) -> cb_context:context().
put(Context, _Carrier) ->
    Payload = cb_context:doc(Context),
    _ = kz_amqp_worker:cast(Payload, fun kapi_im:publish_inbound/1),
    crossbar_util:response(kz_json:normalize(kz_api:remove_defaults(Payload)), Context).

%%------------------------------------------------------------------------------
%% @doc
%% Validate message content against carrier's im schema
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, Carrier) ->
    validate_message(Context, Carrier, cb_context:req_verb(Context)).

-spec validate_message(cb_context:context(), path_token(), http_method()) -> cb_context:context().
validate_message(Context, Carrier, ?HTTP_POST) ->
    create(Context, Carrier).

%%------------------------------------------------------------------------------
%% @doc Create a new instance with the data provided, if it is valid
%% @end
%%------------------------------------------------------------------------------
-spec create(cb_context:context(), path_token()) -> cb_context:context().
create(Context, Carrier) ->
    OnSuccess = fun(Ctx) -> on_successful_validation(Ctx, Carrier) end,
    KzdCarrier = binary_to_atom(<<"kzd_", Carrier/binary, "_im">>),
    case kz_module:is_exported(KzdCarrier, 'type', 0) of
        'true' ->
            cb_context:validate_request_data(KzdCarrier:type(), Context, OnSuccess);
        'false' ->
            cb_context:validate_request_data('undefined', Context, OnSuccess)
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec on_successful_validation(cb_context:context(), path_token()) -> cb_context:context().
on_successful_validation(Context, Carrier) ->
    Setters = [{fun carrier_validate/2, Carrier}
              ,fun to_number_exists/1
              ,fun determine_account/1
              ,fun account_is_enabled/1
              ,fun account_is_in_good_standing/1
              ,fun account_has_messaging_enabled/1
              ,fun reseller_is_in_good_standing/1
              ,fun reseller_has_messaging_enabled/1
              ,fun create_request/1
              ],
    cb_context:validators(Context, Setters).

%%------------------------------------------------------------------------------
%% validation callbacks
%%
%%------------------------------------------------------------------------------

-spec carrier_validate(cb_context:context(), path_token()) -> cb_context:context().
carrier_validate(Context, Carrier) ->
    KzdCarrier = binary_to_atom(<<"knm_", Carrier/binary>>),
    Payload = cb_context:req_data(Context),
    case kz_module:is_exported(KzdCarrier, 'validate_im', 1) of
        true ->
            handle_carrier_validate(Context
                                   ,KzdCarrier:validate_im(Payload)
                                   );
        _ ->
            cb_context:add_system_error('bad_identifier', Carrier, Context)
    end.

handle_carrier_validate(Context, {error, _Error}) ->
    cb_context:add_system_error('parse_error', Context);
handle_carrier_validate(Context, {ok, JObj}) ->
    cb_context:set_doc(Context, JObj).

-spec to_number_exists(cb_context:context()) -> cb_context:context().
to_number_exists(Context) ->
    Doc = cb_context:doc(Context),
    [Number] = kz_im:to(Doc),
    case knm_phone_number:fetch(Number) of
        {'error', _R} -> cb_context:add_validation_error(<<"to">>, <<"invalid">>, <<"number is invalid">>, Context);
        {'ok', KNumber} -> cb_context:store(Context, 'kazoo_number', KNumber)
    end.

-spec determine_account(cb_context:context()) -> cb_context:context().
determine_account(Context) ->
    KNumber = cb_context:fetch(Context, 'kazoo_number'),
    Account = knm_phone_number:assigned_to(KNumber),
    Context1 = cb_context:set_account_id(Context, Account),
    cb_context:set_reseller_id(Context1,kz_services_reseller:get_id(Account)).

-spec account_is_enabled(cb_context:context()) -> cb_context:context().
account_is_enabled(Context) ->
    AccountDoc = cb_context:account_doc(Context),
    case kzd_accounts:enabled(AccountDoc) of
        'true' -> Context;
        'false' -> cb_context:add_system_error('disabled', Context)
    end.

-spec account_is_in_good_standing(cb_context:context()) -> cb_context:context().
account_is_in_good_standing(Context) ->
    AccountId = cb_context:account_id(Context),
    case kz_services_standing:acceptable(AccountId) of
        {'true', _} -> Context;
        {'false', #{message := Msg}} -> cb_context:add_system_error('account', Msg, Context)
    end.

-spec account_has_messaging_enabled(cb_context:context()) -> cb_context:context().
account_has_messaging_enabled(Context) ->
    Doc = cb_context:doc(Context),
    case kz_im:type(Doc) of
        <<"sms">> ->
            case kz_services_im:is_sms_enabled(cb_context:account_id(Context)) of
                'true' -> Context;
                'false' -> cb_context:add_system_error('account', <<"sms services not enabled for account">>, Context)
            end;
        <<"mms">> ->
            case kz_services_im:is_mms_enabled(cb_context:account_id(Context)) of
                'true' -> Context;
                'false' -> cb_context:add_system_error('account', <<"mms services not enabled for account">>, Context)
            end
    end.

-spec reseller_is_in_good_standing(cb_context:context()) -> cb_context:context().
reseller_is_in_good_standing(Context) ->
    case kz_services_standing:acceptable(cb_context:reseller_id(Context)) of
        {'true', _} -> Context;
        {'false', #{message := Msg}} ->
            lager:warning("reseller ~s for account ~s is not in good standing => ~p"
                         ,[cb_context:reseller_id(Context)
                          ,cb_context:account_id(Context)
                          ,Msg
                          ]
                         ),
            cb_context:add_system_error('account', <<"service temporarily unavailable">>, Context)
    end.

-spec reseller_has_messaging_enabled(cb_context:context()) -> cb_context:context().
reseller_has_messaging_enabled(Context) ->
    Doc = cb_context:doc(Context),
    case kz_im:type(Doc) of
        <<"sms">> ->
            case kz_services_im:is_sms_enabled(cb_context:reseller_id(Context)) of
                'true' -> Context;
                'false' ->
                    lager:warning("sms services not enabled for reseller ~s of account ~s"
                                 ,[cb_context:reseller_id(Context)
                                  ,cb_context:account_id(Context)
                                  ]
                                 ),
                    cb_context:add_system_error('account', <<"service temporarily unavailable">>, Context)
            end;
        <<"mms">> ->
            case kz_services_im:is_sms_enabled(cb_context:reseller_id(Context)) of
                'true' -> Context;
                'false' ->
                    lager:warning("mms services not enabled for reseller ~s of account ~s"
                                 ,[cb_context:reseller_id(Context)
                                  ,cb_context:account_id(Context)
                                  ]
                                 ),
                    cb_context:add_system_error('account', <<"service temporarily unavailable">>, Context)
            end
    end.

-spec create_request(cb_context:context()) -> cb_context:context().
create_request(Context) ->
    Doc = cb_context:doc(Context),
    CCVs = [{<<"Account-ID">>, cb_context:account_id(Context)}
           ,{<<"Reseller-ID">>, cb_context:reseller_id(Context)}
           ],
    KVs = kz_json:from_list([{<<"Message-ID">>, cb_context:req_id(Context)}
                            ,{<<"Account-ID">>, cb_context:account_id(Context)}
                            ,{<<"Custom-Vars">>, kz_json:from_list(CCVs)}
                            ,{<<"Msg-ID">>, cb_context:req_id(Context)}
                            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
                            ]),
    cb_context:set_doc(Context, kz_json:merge(KVs, Doc)).
