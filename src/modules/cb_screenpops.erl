%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @author Kevin
%%% @doc Endpoint for screenpops
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_screenpops).

-export([init/0
        ,allowed_methods/0, allowed_methods/1
        ,resource_exists/0, resource_exists/1
        ,validate/1, validate/2
        ,put/1
        ,post/2
        ,patch/2
        ]).

-include_lib("crossbar/src/crossbar.hrl").

-define(CB_LIST, <<"screenpops/config_listing">>).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Initializes the bindings this module will respond to.
%% @end
%%------------------------------------------------------------------------------
-spec init() -> 'ok'.
init() ->
    _ = crossbar_bindings:bind(<<"*.allowed_methods.screenpops">>, ?MODULE, 'allowed_methods'),
    _ = crossbar_bindings:bind(<<"*.resource_exists.screenpops">>, ?MODULE, 'resource_exists'),
    _ = crossbar_bindings:bind(<<"*.validate.screenpops">>, ?MODULE, 'validate'),
    _ = crossbar_bindings:bind(<<"*.execute.get.screenpops">>, ?MODULE, 'get'),
    _ = crossbar_bindings:bind(<<"*.execute.put.screenpops">>, ?MODULE, 'put'),
    _ = crossbar_bindings:bind(<<"*.execute.post.screenpops">>, ?MODULE, 'post'),
    _ = crossbar_bindings:bind(<<"*.execute.patch.screenpops">>, ?MODULE, 'patch').

%%------------------------------------------------------------------------------
%% @doc Given the path tokens related to this module, what HTTP methods are
%% going to be responded to.
%% @end
%%------------------------------------------------------------------------------

-spec allowed_methods() -> http_methods().
allowed_methods() ->
    [?HTTP_GET, ?HTTP_PUT].

-spec allowed_methods(path_token()) -> http_methods().
allowed_methods(_ScreenpopId) ->
    [?HTTP_GET, ?HTTP_POST, ?HTTP_PATCH].

%%------------------------------------------------------------------------------
%% @doc Does the path point to a valid resource
%% @end
%%------------------------------------------------------------------------------

-spec resource_exists() -> 'true'.
resource_exists() -> 'true'.

-spec resource_exists(path_token()) -> 'true'.
resource_exists(_) -> 'true'.

%%------------------------------------------------------------------------------
%% @doc This function determines if the parameters and content are correct
%% for this request
%%
%% Failure here returns 400.
%% @end
%%------------------------------------------------------------------------------
-spec validate(cb_context:context()) -> cb_context:context().
validate(Context) ->
    validate_request(Context, cb_context:req_verb(Context)).
validate_request(Context, ?HTTP_GET) ->
    load_summary(Context);
validate_request(Context, ?HTTP_PUT) ->
    create_entry(Context).



-spec validate(cb_context:context(), path_token()) -> cb_context:context().
validate(Context, ScreenpopId) ->
    validate_request(Context, ScreenpopId, cb_context:req_verb(Context)).

validate_request(Context, DocId, ?HTTP_GET) ->
    load_entry(DocId, Context);

validate_request(Context, ScreenpopId, ?HTTP_PATCH) ->
    RespContext = load_entry(ScreenpopId, Context),
    case cb_context:has_errors(RespContext) of
        'false' -> validate_patch(ScreenpopId, Context);
        'true' -> RespContext
    end;
validate_request(Context, ScreenpopId, ?HTTP_POST) ->
    RespContext = load_entry(ScreenpopId, Context),
    case cb_context:has_errors(RespContext) of
        'false' -> update_entry(ScreenpopId, Context);
        'true' ->  RespContext
    end.

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is PUT, execute the actual action, usually a db save.
%% @end
%%------------------------------------------------------------------------------
-spec put(cb_context:context()) -> cb_context:context().
put(Context) ->
    crossbar_doc:save(Context).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is POST, execute the actual action, usually a db save
%% (after a merge perhaps).
%% @end
%%------------------------------------------------------------------------------
-spec post(cb_context:context(), path_token()) -> cb_context:context().
post(Context, _) ->
    crossbar_doc:save(Context).

%%------------------------------------------------------------------------------
%% @doc If the HTTP verb is PATCH, execute the actual action, usually a db save
%% (after a merge perhaps).
%% @end
%%------------------------------------------------------------------------------
-spec patch(cb_context:context(), path_token()) -> cb_context:context().
patch(Context, _) ->
    crossbar_doc:save(Context).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Attempt to load list of accounts, each summarized. Or a specific
%% account summary.
%% @end
%%------------------------------------------------------------------------------
-spec load_summary(cb_context:context()) -> cb_context:context().
load_summary(Context) ->
    crossbar_view:load(Context, ?CB_LIST, [{'mapper', crossbar_view:get_value_fun()}]).

-spec load_entry(kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
load_entry(DocId, Context) ->
    crossbar_doc:load(DocId, Context, ?TYPE_CHECK_OPTION(<<"screenpops">>)).

%%------------------------------------------------------------------------------
%% @doc Create a new document with the data provided, if it is valid
%% @end
%%------------------------------------------------------------------------------
-spec create_entry(cb_context:context()) -> cb_context:context().
create_entry(Context) ->
    OnSuccess = fun(C) -> on_successful_validation('undefined', C) end,
    cb_context:validate_request_data(<<"screenpops">>, Context, OnSuccess).


%%------------------------------------------------------------------------------
%% @doc Update-merge an existing document with the data provided, if it is
%% valid
%% @end
%%------------------------------------------------------------------------------
-spec validate_patch(kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
validate_patch(DocId, Context) ->
    crossbar_doc:patch_and_validate(DocId, Context, fun update_entry/2).

%%------------------------------------------------------------------------------
%% @doc Update an existing document with the data provided, if it is
%% valid
%% @end
%%------------------------------------------------------------------------------
-spec update_entry(kz_term:ne_binary(), cb_context:context()) -> cb_context:context().
update_entry(DocId, Context) ->
    OnSuccess = fun(C) -> on_successful_validation(DocId, C) end,
    cb_context:validate_request_data(<<"screenpops">>, Context, OnSuccess).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec on_successful_validation(kz_term:api_binary(), cb_context:context()) ->
          cb_context:context().
on_successful_validation('undefined', Context) ->
    cb_context:set_doc(Context, kz_json:set_values([{<<"pvt_type">>, <<"screenpops">>}
                                                   ,{<<"pvt_vsn">>, <<"1">>}
                                                   ]
                                                  ,cb_context:doc(Context)
                                                  ));
on_successful_validation(DocId, Context) ->
    crossbar_doc:load_merge(DocId, Context, ?TYPE_CHECK_OPTION(<<"screenpops">>)).
