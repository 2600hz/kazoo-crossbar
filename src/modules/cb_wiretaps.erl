%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2023, 2600Hz
%%% @doc Manages wiretap configurations on accounts, devices, and users.
%%%
%%% @end
%%% @author Daniel Finke <danielfinke2011@gmail.com>
%%%-----------------------------------------------------------------------------
-module(cb_wiretaps).

%%%=============================================================================
%%% Export and Defs
%%%=============================================================================

%% External API
-export([init/0
        ,allowed_methods/0, allowed_methods/1
        ,authorize/1, authorize/2
        ,resource_exists/0, resource_exists/1
        ,validate/1, validate/2
        ,post/2
        ,patch/2
        ,delete/2
        ]).

-include_lib("kazoo_stdlib/include/kazoo_json.hrl").
-include("crossbar.hrl").

-define(EXPECTED_TYPES, [kzd_accounts:type()
                        ,kzd_devices:type()
                        ,kzd_users:type()
                        ]).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    Bindings = [{<<"*.allowed_methods.wiretaps">>, 'allowed_methods'}
               ,{<<"*.authorize.wiretaps">>, 'authorize'}
               ,{<<"*.resource_exists.wiretaps">>, 'resource_exists'}
               ,{<<"*.validate.wiretaps">>, 'validate'}
               ,{<<"*.execute.post.wiretaps">>, 'post'}
               ,{<<"*.execute.patch.wiretaps">>, 'patch'}
               ,{<<"*.execute.delete.wiretaps">>, 'delete'}
               ],
    cb_modules_util:bind(?MODULE, Bindings).

%%------------------------------------------------------------------------------
%% @doc Get the HTTP methods that are going to be responded to.
%% @end
%%------------------------------------------------------------------------------
-spec allowed_methods() -> http_methods().
allowed_methods() -> [?HTTP_GET].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_EndpointId) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_PATCH, ?HTTP_DELETE].

%%------------------------------------------------------------------------------
%% @doc Authorizes the incoming request, returning true if the requestor is
%% allowed to access the resource, or false if not.
%% @end
%%------------------------------------------------------------------------------
-spec authorize(cb_context:context()) -> cb_context:context().
authorize(Context) ->
    cb_context:is_superduper_admin(Context)
        %% Hide existence of wiretaps API
        orelse {'stop', cb_context:add_system_error('not_found', Context)}.

-spec authorize(cb_context:context(), path_token()) -> cb_context:context().
authorize(Context, _EndpointId) -> authorize(Context).

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource.
%% @end
%%------------------------------------------------------------------------------
-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_EndpointId) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc Check the request (request body, query string params, path tokens, etc)
%% and load necessary information.
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_request(Context, cb_context:req_verb(Context)).

-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, EndpointId) ->
    validate_request(Context, EndpointId, cb_context:req_verb(Context)).

%%------------------------------------------------------------------------------
%% @doc Update/set a wiretap configuration.
%% @end
%%------------------------------------------------------------------------------
-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _EndpointId) -> update_doc(Context).

%%------------------------------------------------------------------------------
%% @doc Patch a wiretap configuration.
%% @end
%%------------------------------------------------------------------------------
-spec patch(cb_context:context(), path_token()) -> cb_context:context().
patch(Context, _EndpointId) ->
    ReqData = cb_context:req_data(Context),
    Doc = cb_context:doc(Context),
    WiretapSettings = kzd_endpoint:pvt_wiretap(Doc),
    WiretapSettings1 = kz_json:merge([WiretapSettings, ReqData]),
    update_doc(Context, WiretapSettings1).

%%------------------------------------------------------------------------------
%% @doc Delete a wiretap configuration.
%% @end
%%------------------------------------------------------------------------------
-spec delete(cb_context:context(), path_token()) -> cb_context:context().
delete(Context, _EndpointId) -> update_doc(Context, kz_json:new()).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Check the request (request body, query string params, path tokens, etc)
%% and load necessary information.
%% @end
%%------------------------------------------------------------------------------
-spec validate_request(cb_context:context(), http_method()) -> cb_context:context().
validate_request(Context, ?HTTP_GET) ->
    Options = [{'mapper', crossbar_view:get_value_fun()}],
    crossbar_view:load(Context, <<"crossbar_listings/wiretaps">>, Options).

-spec validate_request(cb_context:context(), path_token(), http_method()) ->
          cb_context:context().
validate_request(Context, EndpointId, ?HTTP_GET) ->
    Options = [{'doc_normalizer', fun normalize_doc/1}],
    Context1 = load_doc(EndpointId, Context, Options),
    case cb_context:has_errors(Context1) of
        'true' -> Context1;
        'false' -> validate_doc_has_wiretap_settings(Context1)
    end;
validate_request(Context, EndpointId, _) -> load_doc(EndpointId, Context).

%%------------------------------------------------------------------------------
%% @equiv load_doc(Id, Context, [])
%%------------------------------------------------------------------------------
-spec load_doc(kazoo_data:docid(), cb_context:context()) -> cb_context:context().
load_doc(Id, Context) -> load_doc(Id, Context, []).

%%------------------------------------------------------------------------------
%% @doc Load an endpoint document.
%% @end
%%------------------------------------------------------------------------------
-spec load_doc(kazoo_data:docid(), cb_context:context(), crossbar_doc:load_options()) ->
          cb_context:context().
load_doc(Id, Context, Options) ->
    Options1 = Options ++ ?TYPE_CHECK_OPTION(?EXPECTED_TYPES),
    crossbar_doc:load(Id, Context, Options1).

%%------------------------------------------------------------------------------
%% @doc Normalize endpoint documents for this API. Affects response data.
%% @end
%%------------------------------------------------------------------------------
-spec normalize_doc(kz_json:object()) -> kz_json:object().
normalize_doc(Doc) ->
    kz_json:set_values([{kz_doc:path_id(), kz_doc:id(Doc)}
                       ,{<<"type">>, kz_doc:type(Doc)}
                       ,{<<"settings">>, kzd_endpoint:pvt_wiretap(Doc)}
                       ], kz_json:new()).

%%------------------------------------------------------------------------------
%% @doc Validate that the endpoint doc in the context has wiretap settings. If
%% not, this API treats the request as a 404.
%% @end
%%------------------------------------------------------------------------------
-spec validate_doc_has_wiretap_settings(cb_context:context()) -> cb_context:context().
validate_doc_has_wiretap_settings(Context) ->
    Doc = cb_context:doc(Context),
    case kz_json:get_json_value(<<"settings">>, Doc) of
        'undefined' ->
            ErrorCause = kz_json:from_list([{<<"cause">>, kz_doc:id(Doc)}]),
            cb_context:add_system_error('bad_identifier', ErrorCause, Context);
        _ -> Context
    end.

%%------------------------------------------------------------------------------
%% @equiv update_doc(Context, cb_context:req_data(Context))
%%------------------------------------------------------------------------------
-spec update_doc(cb_context:context()) -> cb_context:context().
update_doc(Context) -> update_doc(Context, cb_context:req_data(Context)).

%%------------------------------------------------------------------------------
%% @doc Update the wiretap settings on the endpoint doc. The doc key is removed
%% if the new settings are empty.
%% @end
%%------------------------------------------------------------------------------
-spec update_doc(cb_context:context(), kz_json:object()) -> cb_context:context().
update_doc(Context, WiretapSettings) ->
    Doc = cb_context:doc(Context),
    Doc1 = case WiretapSettings of
               ?EMPTY_JSON_OBJECT -> kzd_endpoint:delete_pvt_wiretap(Doc);
               _ -> kzd_endpoint:set_pvt_wiretap(Doc, WiretapSettings)
           end,
    Context1 = crossbar_doc:save(cb_context:set_doc(Context, Doc1)),
    case cb_context:has_errors(Context1) of
        'true' -> Context1;
        'false' ->
            RespData = kz_doc:public_fields(normalize_doc(Doc1)),
            cb_context:set_resp_data(Context1, RespData)
    end.
