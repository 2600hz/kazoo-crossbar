%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2025, 2600Hz
%%% @doc Handle client requests for phone_number documents
%%% @author Karl Anderson
%%% @author James Aimonetti
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_addresses).

-export([init/0
        ,allowed_methods/0, allowed_methods/1
        ,resource_exists/1, resource_exists/0
        ,validate/1, validate/2
        ,validate_request/2
        ,put/1
        ,post/2
        ,patch/2
        ,delete/2
        ]).

-include("crossbar.hrl").

-define(NUM_LIST, <<"addresses/used_by_numbers">>).
-define(CB_LIST, <<"addresses/list_by_id">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = cb_modules_util:bind(?MODULE, [{<<"*.allowed_methods.addresses">>, 'allowed_methods'}
                                      ,{<<"*.resource_exists.addresses">>, 'resource_exists'}
                                      ,{<<"*.validate.addresses">>, 'validate'}
                                      ,{<<"*.execute.put.addresses">>, 'put'}
                                      ,{<<"*.execute.post.addresses">>, 'post'}
                                      ,{<<"*.execute.patch.addresses">>, 'patch'}
                                      ,{<<"*.execute.delete.addresses">>, 'delete'}
                                      ]),
    'ok'.

%%------------------------------------------------------------------------------
%% @doc This function determines the verbs that are appropriate for the
%% given Nouns. For example `/accounts/' can only accept `GET' and `PUT'.
%%
%% Failure here returns `405 Method Not Allowed'.
%% @end
%%------------------------------------------------------------------------------

-spec allowed_methods() -> http_methods().
allowed_methods() ->
    [?HTTP_PUT, ?HTTP_GET].

-spec allowed_methods(kz_term:ne_binary()) -> http_methods().
allowed_methods(_AddressId) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_PATCH, ?HTTP_DELETE].

%%------------------------------------------------------------------------------
%% @doc This function determines if the provided list of Nouns are valid.
%% Failure here returns `404 Not Found'.
%% @end
%%------------------------------------------------------------------------------

-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_Id) ->
    'true'.

%%------------------------------------------------------------------------------
%% @doc This function determines if the parameters and content are correct
%% for this request
%%
%% Failure here returns 400.
%% @end
%%------------------------------------------------------------------------------

-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_addresses(Context, cb_context:req_verb(Context)).

validate_addresses(Context, ?HTTP_GET) ->
    summary(Context);
                                                % Context;

validate_addresses(Context, ?HTTP_PUT) ->
    validate_request('undefined', Context).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, PathToken) ->
    validate_address(Context, PathToken, cb_context:req_verb(Context)).

validate_address(Context, Id, ?HTTP_GET) ->
    read(Id, Context);

validate_address(Context, Id, ?HTTP_POST) ->
    validate_request(Id, Context);

validate_address(Context, Id, ?HTTP_PATCH) ->
    validate_patch(Id, Context);

validate_address(Context, Id, ?HTTP_DELETE) ->
    read(Id, Context).


%%------------------------------------------------------------------------------
%% @doc Validate a request
%% @end
%%------------------------------------------------------------------------------
-spec validate_request(kz_term:api_ne_binary(), cb_context:context()) -> cb_context:context().
validate_request(Id, Context) ->
    check_address_schema(Id, Context).

%%------------------------------------------------------------------------------
%% @doc Validate a patch
%% @end
%%------------------------------------------------------------------------------

-spec validate_patch(kz_term:api_ne_binary(), cb_context:context()) -> cb_context:context().
validate_patch(Id, Context) ->
    crossbar_doc:patch_and_validate(Id, Context, fun validate_request/2).

check_address_schema(Id, Context) ->
    OnSuccess = fun(C) -> on_successful_validation(Id, C) end,
    cb_context:validate_request_data(<<"addresses">>, Context, OnSuccess).

%%------------------------------------------------------------------------------
%% @doc Validate a patch
%% @end
%%------------------------------------------------------------------------------
-spec on_successful_validation(kz_term:api_ne_binary(), cb_context:context()) ->
          cb_context:context().
on_successful_validation('undefined', Context) ->
    Props = [{<<"pvt_type">>, <<"addresses">>}],
    cb_context:set_doc(Context, kz_json:set_values(Props, cb_context:doc(Context)));

on_successful_validation(Id, Context) ->
    crossbar_doc:load_merge(Id, Context).


%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is POST, execute the actual action, usually a db save
%% (after a merge perhaps).
%% @end
%%------------------------------------------------------------------------------

-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _) ->
    crossbar_doc:save(Context).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is PATCH, merge then execute the save
%% @end
%%------------------------------------------------------------------------------
-spec patch(cb_context:context(), path_token()) -> cb_context:context().
patch(Context, Id) ->
    post(Context, Id).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is DELETE, execute the actual action, usually a db delete
%% @end
%%------------------------------------------------------------------------------

-spec delete(cb_context:context(), path_token()) -> cb_context:context().
delete(Context, Id) ->
    case used_by_numbers(Context, Id) of
        [] ->
            crossbar_doc:delete(Context);
        Numbers ->
            Ctx1 = cb_context:set_resp_data(cb_context:set_resp_status(Context, 'error'),
                                            kz_json:from_list([{<<"Reason">>, <<"Address is used by these numbers">>},
                                                               {<<"Numbers">>, Numbers}])),
            cb_context:set_resp_error_code(Ctx1, 409)
    end.

used_by_numbers(Context, Id) ->
    Option= [{'key', Id}],
    AccountDb = cb_context:db_name(Context),
    case kz_datamgr:get_results(AccountDb, ?NUM_LIST, Option) of
        {'ok', Numbers} -> [kz_doc:id(E) || E <- Numbers];
        {_, _} -> []
    end.

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is PUT, execute the actual action, usually a db save.
%% @end
%%------------------------------------------------------------------------------
-spec put(cb_context:context()) -> cb_context:context().
put(Context) ->
    crossbar_doc:save(Context).

-spec read(kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
read(Id, Context) ->
    crossbar_doc:load(Id, Context).


-spec summary(cb_context:context()) -> cb_context:context().
summary(Context) ->
    try_load_view(Context, 'true').

-spec try_load_view(cb_context:context(), boolean()) -> cb_context:context().
try_load_view(Context, 'false') ->
    crossbar_view:load(Context, ?CB_LIST, [{'mapper', fun normalize_view_results/2}]);
try_load_view(Context, 'true') ->
    Res = try_load_view(Context, 'false'),
    case cb_context:resp_status(Res) of
        'success' ->
            Res;
        'fatal' ->
            maybe_create_view(Res, cb_context:resp_error_msg(Res));
        _Other ->
            Res
    end.

maybe_create_view(Context, <<"datastore missing view">>) ->
    _ = kapps_maintenance:refresh(cb_context:db_name(Context)),
    try_load_view(Context, 'false');

maybe_create_view(Context, _OtherFailure) ->
    Context.

%%------------------------------------------------------------------------------
%% @doc Normalizes the results of a view
%% @end
%%------------------------------------------------------------------------------
-spec normalize_view_results(kz_json:object(), kz_json:objects()) -> kz_json:objects().
normalize_view_results(JObj, Acc) ->
    [kz_json:get_json_value(<<"value">>, JObj) | Acc].
