%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2020, 2600Hz
%%% @doc Crossnar API for skel.
%%% @author Karl Anderson
%%% @author James Aimonetti
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_external_numbers).

-export([init/0
        ,allowed_methods/0, allowed_methods/1, allowed_methods/2
        ,resource_exists/0, resource_exists/1, resource_exists/2
        ,validate/1, validate/2, validate/3
        ,put/1, put/3
        ,post/3
        ,delete/2
        ]).

-include("crossbar.hrl").

-define(VERIFY, <<"verify">>).
-define(PVT_TYPE, kzd_external_numbers:type()).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.allowed_methods.external_numbers">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.external_numbers">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.external_numbers">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.get.external_numbers">>, ?MODULE, 'get'),
    _ = crossbar_bindings:bind(<<"*.execute.put.external_numbers">>, ?MODULE, 'put'),
    _ = crossbar_bindings:bind(<<"*.execute.post.external_numbers">>, ?MODULE, 'post'),
    _ = crossbar_bindings:bind(<<"*.execute.delete.external_numbers">>, ?MODULE, 'delete').

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------

-spec allowed_methods() -> http_methods().
allowed_methods() ->
    [?HTTP_GET, ?HTTP_PUT].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_Thing) ->
    [?HTTP_GET, ?HTTP_DELETE].

-spec allowed_methods(path_token(), path_token()) -> http_methods().
allowed_methods(_Thing, ?VERIFY) ->
    [?HTTP_PUT, ?HTTP_POST].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource.
%% @end
%%------------------------------------------------------------------------------

-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_) -> 'true'.

-spec resource_exists(path_token(), path_token()) -> 'true'.
resource_exists(_, ?VERIFY) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Check the request (request body, query string params, path tokens, etc)
%% and load necessary information.
%% @end
%%------------------------------------------------------------------------------

-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_external_numbers(Context, cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, Id) ->
    validate_external_number(Context, Id, cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token(), path_token()) -> cb_context:context().
validate(Context, Id, ?VERIFY) ->
    validate_external_number_verify(Context, Id, cb_context:req_verb(Context)).

-spec validate_external_numbers(cb_context:context(), http_method()) -> cb_context:context().
validate_external_numbers(Context, ?HTTP_GET) ->
    summary(Context);
validate_external_numbers(Context, ?HTTP_PUT) ->
    create(Context).

-spec validate_external_number(cb_context:context(), path_token(), http_method()) -> cb_context:context().
validate_external_number(Context, Id, ?HTTP_GET) ->
    read(Id, Context);
validate_external_number(Context, Id, ?HTTP_DELETE) ->
    read(Id, Context).

-spec validate_external_number_verify(cb_context:context(), path_token(), http_method()) -> cb_context:context().
validate_external_number_verify(Context, Id, ?HTTP_PUT) ->
    OnSuccess = fun(C) -> read(Id, C) end,
    cb_context:validate_request_data(<<"external_number_verify">>, Context, OnSuccess);
validate_external_number_verify(Context, Id, ?HTTP_POST) ->
    OnSuccess = fun(C) -> read(Id, C) end,
    cb_context:validate_request_data(<<"external_number_claim">>, Context, OnSuccess).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is PUT, execute the actual action, usually a db save.
%% @end
%%------------------------------------------------------------------------------
-spec put(cb_context:context()) -> cb_context:context().
put(Context) ->
    crossbar_doc:save(Context).

-spec put(cb_context:context(), path_token(), path_token()) -> cb_context:context().
put(Context, _Id, ?VERIFY) ->
    Context1 = crossbar_doc:save(update_pin(Context)),
    case cb_context:resp_status(Context1) of
        'success' -> send_verification_pin(Context1);
        _Else -> Context1
    end.

-spec update_pin(cb_context:context()) -> cb_context:context().
update_pin(Context) ->
    Doc = cb_context:doc(Context),
    Pin = kz_term:to_binary(kz_term:rand_integer(1000, 9999)),
    Setters = [{fun kzd_external_numbers:set_attestation/2, kz_json:new()}
              ,{fun kzd_external_numbers:set_pvt_pin/2, Pin}
              ,{fun kzd_external_numbers:set_pvt_verified/2, 'false'}
              ],
    cb_context:set_doc(Context, kz_doc:setters(Doc, Setters)).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is POST, execute the actual action, usually a db save
%% (after a merge perhaps).
%% @end
%%------------------------------------------------------------------------------
-spec post(cb_context:context(), path_token(), path_token()) -> cb_context:context().
post(Context, _Id, ?VERIFY) ->
    Doc = cb_context:doc(Context),
    Pin = kzd_external_numbers:pvt_pin(Doc),
    case Pin =:= kz_json:get_ne_binary_value(<<"pin">>, cb_context:req_data(Context)) of
        'true' -> number_verified(Context);
        'false' ->
            cb_context:add_validation_error(<<"pin">>, <<"invalid">>, <<"pin does not match">>, Context)
    end.

-spec number_verified(cb_context:context()) -> cb_context:context().
number_verified(Context) ->
    Doc = cb_context:doc(Context),
    AccountId = cb_context:auth_account_id(Context),
    UserId = cb_context:auth_user_id(Context),
    Setters = [{fun kzd_external_numbers:set_attestation_date/2, kz_time:now_s()}
              ,{fun kzd_external_numbers:set_attestation_token_method/2
               ,kz_json:get_ne_binary_value(<<"method">>, cb_context:auth_doc(Context))
               }
              ,{fun kzd_external_numbers:set_attestation_token_source/2
               ,cb_context:client_ip(Context)
               }
              ,{fun kzd_external_numbers:set_attestation_account_id/2, AccountId}
              ,{fun kzd_external_numbers:set_attestation_account_name/2
               ,kzd_accounts:fetch_name(AccountId)
               }
              ,{fun kzd_external_numbers:set_attestation_user_id/2, UserId}
              ,{fun kzd_external_numbers:set_attestation_user_name/2, <<>>}
              ,{fun kzd_external_numbers:set_pvt_verified/2, 'true'}
              ,{fun kzd_external_numbers:set_pvt_pin/2, 'undefined'}
              ],
    crossbar_doc:save(cb_context:set_doc(Context, kz_doc:setters(Doc, Setters))).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is DELETE, execute the actual action, usually a db delete
%% @end
%%------------------------------------------------------------------------------
-spec delete(cb_context:context(), path_token()) -> cb_context:context().
delete(Context, _) ->
    crossbar_doc:delete(Context).

%%------------------------------------------------------------------------------
%% @doc Create a new instance with the data provided, if it is valid
%% @end
%%------------------------------------------------------------------------------
-spec create(cb_context:context()) -> cb_context:context().
create(Context) ->
    OnSuccess = fun additional_create_validation/1,
    cb_context:validate_request_data(<<"external_numbers">>, Context, OnSuccess).

-spec additional_create_validation(cb_context:context()) -> cb_context:context().
additional_create_validation(Context) ->
    Routines = [fun validate_number_reconcilable/1
               ,fun validate_number_unique/1
               ],
    lists:foldl(fun(F, C) -> F(C) end, initalize_fields(Context), Routines).

-spec initalize_fields(cb_context:context()) -> cb_context:context().
initalize_fields(Context) ->
    Doc = cb_context:doc(Context),
    Number = knm_converters:normalize(
               kzd_external_numbers:number(Doc)
              ),
    Setters = [{fun kzd_external_numbers:set_number/2, Number}
              ,{fun kzd_external_numbers:set_attestation/2, kz_json:new()}
              ,{fun kzd_external_numbers:set_pvt_verified/2, 'false'}
              ,{fun kz_doc:set_type/2, ?PVT_TYPE}
              ],
    cb_context:set_doc(Context, kz_doc:setters(Doc, Setters)).

-spec validate_number_reconcilable(cb_context:context()) -> cb_context:context().
validate_number_reconcilable(Context) ->
    Number = kzd_external_numbers:number(cb_context:doc(Context)),
    case knm_converters:is_reconcilable(Number) of
        'true' -> Context;
        'false' ->    
            cb_context:add_validation_error(<<"number">>, <<"invalid">>, <<"number is not an external number">>, Context)
    end.

-spec validate_number_unique(cb_context:context()) -> cb_context:context().
validate_number_unique(Context) ->
    Number = kzd_external_numbers:number(cb_context:doc(Context)),
    AccountId = cb_context:account_id(Context),
    PhoneNumbers = props:get_keys(knm_numbers:account_listing(AccountId)),
    case lists:member(Number, PhoneNumbers) of
        'true' ->
            cb_context:add_validation_error(<<"number">>, <<"unique">>, <<"number is already assigned as a phone number">>, Context);
        'false' ->
            ExternalNumbers = get_external_numbers(Context),
            case lists:member(Number, ExternalNumbers) of
                'true' ->
                    cb_context:add_validation_error(<<"number">>, <<"unique">>, <<"number is already assigned as an external number">>, Context);
                'false' ->
                    Context
            end
    end.

-spec get_external_numbers(cb_context:context()) -> kz_term:ne_binaries().
get_external_numbers(Context) ->
    AccountId = cb_context:account_id(Context),
    ViewOptions = [{'startkey', [kzd_external_numbers:type()]}
                  ,{'endkey', [kzd_external_numbers:type(), kz_json:new()]}
                  ],
    case kz_datamgr:get_results(AccountId, <<"crossbar_listings/by_type_number">>, ViewOptions) of
        {'ok', JObjs} ->
            [kzd_external_numbers:number(
               kz_json:get_json_value(<<"value">>, JObj)
              )
             || JObj <- JObjs
            ];
        _Else -> []
    end.

%%------------------------------------------------------------------------------
%% @doc Load an instance from the database
%% @end
%%------------------------------------------------------------------------------
-spec read(kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
read(Id, Context) ->
    crossbar_doc:load(Id, Context, ?TYPE_CHECK_OPTION(?PVT_TYPE)).

%%------------------------------------------------------------------------------
%% @doc Attempt to load a summarized listing of all instances of this
%% resource.
%% @end
%%------------------------------------------------------------------------------
-spec summary(cb_context:context()) -> cb_context:context().
summary(Context) ->
    Options = [{'doc_type', ?PVT_TYPE}
              ,{'mapper', crossbar_view:get_value_fun()}
              ],
    Selector = [{'start', [{<<"doc_type">>, ?PVT_TYPE}]}
               ,{'end', [{<<"doc_type">>, ?PVT_TYPE}]}
               ],
    crossbar_view:find(Context, <<"crossbar_listings/by_type_number">>, Selector, Options).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec send_verification_pin(cb_context:context()) -> cb_context:context().
send_verification_pin(Context) ->
    case kz_json:get_ne_binary_value(<<"method">>, cb_context:req_data(Context)) of
        <<"voice">> -> send_voice_pin(Context)
    end.

-spec send_voice_pin(cb_context:context()) -> cb_context:context().
send_voice_pin(Context) ->
    Doc = cb_context:doc(Context),
    Pin = kzd_external_numbers:pvt_pin(Doc),
    Number = kzd_external_numbers:number(Doc),
    io:format("place verification call to ~s with pin ~s~n", [Number, Pin]),
    Context.

        
    
