%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2020, 2600Hz
%%% @doc
%%% @author Roman Galeev
%%% @author Hesaam Farhang
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(crossbar_view).

-export([load/2, load/3
        ,load_time_range/2, load_time_range/3
        ,load_modb/2, load_modb/3
        ,load_yodb/2, load_yodb/3

        ,direction/1, direction/2

        ,get_page_size/2

        ,suffix_key_fun/1

        ,get_doc_fun/0
        ,get_value_fun/0
        ,get_key_fun/0
        ,get_id_fun/0
        ]).

-export([next_batch/2]).

-export([find/4]).

-include("crossbar.hrl").

%% too many types {{{
-define(CB_SPECIFIC_VIEW_OPTIONS,
        ['ascending', 'databases', 'mapper', 'no_filter', 'no_fields'
        ,'fields', 'field_key'

         %% non-range query
        ,'end_keymap', 'keymap', 'start_keymap'

         %% chunked query
        ,'chunk_size', 'is_chunked', 'unchunkable'

         %% ranged query
        ,'created_to', 'created_from', 'max_range'
        ,'range_end_keymap', 'time_filter_key', 'range_keymap', 'range_start_keymap'
        ,'should_paginate'

         %% start/end key length fixer
        ,'key_min_length'
        ]).
-define(USER_PARAMS_ONLY, ?CB_SPECIFIC_VIEW_OPTIONS -- ['mapper']).

-type time_range() :: {kz_time:gregorian_seconds(), kz_time:gregorian_seconds()}.
%% `{StartTimestamp, EndTimestamp}'.
-type api_range_key() :: 'undefined' | ['undefined'] | kazoo_data:range_key().
-type range_keys() :: {api_range_key(), api_range_key()}.
%% `{Startkey, EndKey}'.
-type keymap_fun() :: fun((cb_context:context()) -> api_range_key()) |
                      fun((cb_context:context(), kazoo_data:view_options()) -> api_range_key()).
%% Function of arity 1 or 2 to create customize start/end key.
-type keymap() :: api_range_key() | keymap_fun().
%% A literal CouchDB `startkey' or `endkey', or a {@link keymap_fun()} for non-range requests.
%% See also {@link build_start_end/3}.

-type range_keymap_fun() :: fun((kz_time:gregorian_seconds()) -> api_range_key()).
%% A function of arity 1. The timestamp from `create_from' or `created_to' will pass to this function
%% to construct the start or end key.
-type range_keymap() :: 'nil' | api_range_key() | range_keymap_fun().
%% Creates a start/end key for ranged queries. A binary or integer or a list of binary or integer
%% to create start/end key. The timestamp will added to end of it.
%% If `undefined' only the timestamp will be used as the key. If timestamp in the view key is at start of the key,
%% use {@link suffix_key_fun}. If the view doesn't need any start/end key you can set this `nil' to bypass setting
%% timestamp as key.

-type user_mapper_fun() :: 'undefined' |
                           fun((kz_json:objects()) -> kz_json:objects() | {'error', any()}) |
                           fun((kz_json:object(), kz_json:objects()) -> kz_json:objects() | {'error', any()}) |
                           fun((cb_context:context(), kz_json:object(), kz_json:objects()) -> kz_json:objects() | {'error', any()}).
%% A function to filter/map view result. For use in Crossbar modules to call {@link crossbar_view} functions.
-type mapper_fun() :: 'undefined' |
                      fun((kz_json:objects()) -> kz_json:objects() | {'error', any()}) |
                      fun((kz_json:object(), kz_json:objects()) -> kz_json:objects() | {'error', any()}).
%% A function to filter/map view result. Internal to {@link crossbar_view}.

-type options() :: kz_view:options() |
                   [{'mapper', user_mapper_fun()} |
                    {'max_range', pos_integer()} |
                    {'no_filter', boolean()} |
                    {'no_fields', boolean()} |
                    {'fields', kz_json:paths()} |
                    {'field_key', kz_term:ne_binary() | 'filtermap'} |

                    %% for non-ranged query
                    {'end_keymap', keymap()} |
                    {'keymap', keymap()} |
                    {'start_keymap', keymap()} |

                    %% for chunked query
                    {'chunk_size', pos_integer()} |
                    {'is_chunked', boolean()} |

                    %% for ranged/modb query
                    {'created_from', pos_integer()} |
                    {'created_to', pos_integer()} |
                    {'range_end_keymap', range_keymap()} |
                    {'range_keymap', range_keymap()} |
                    {'time_filter_key', kz_term:ne_binary()} |
                    {'range_start_keymap', range_keymap()} |
                    {'should_paginate', boolean()} |

                    %% start/end key length fixer
                    {'key_min_length', pos_integer()}
                   ].

-export_type([range_keys/0, time_range/0
             ,options/0
             ,mapper_fun/0 ,user_mapper_fun/0
             ,keymap/0, keymap_fun/0
             ,range_keymap/0, range_keymap_fun/0
             ]
            ).
%% }}}

%% @equiv load(Context, View, [])
-spec load(cb_context:context(), kz_term:ne_binary()) -> cb_context:context().
load(Context, View) ->
    load(Context, View, []).

%%------------------------------------------------------------------------------
%% @doc This function attempts to load the context with the results of a view
%% run against the database.
%% @end
%%------------------------------------------------------------------------------
-spec load(cb_context:context(), kz_term:ne_binary(), options()) -> cb_context:context().
load(Context, View, Options) ->
    CursorOptions = build_cursor_options(Context, Options, 'true', 'false'),
    load_view(Context, View, [], build_range_keys(Context, CursorOptions)).

%% @equiv load_time_range(Context, View, [])
-spec load_time_range(cb_context:context(), kz_term:ne_binary()) -> cb_context:context().
load_time_range(Context, View) ->
    load_time_range(Context, View, []).

%%------------------------------------------------------------------------------
%% @doc This function attempts to load the context with the timestampe
%% results of a view run against the database.
%% @end
%%------------------------------------------------------------------------------
-spec load_time_range(cb_context:context(), kz_term:ne_binary(), options()) -> cb_context:context().
load_time_range(Context, View, Options) ->
    CursorOptions = build_cursor_options(Context, Options, 'true', 'true'),
    load_view(Context, View, [], build_time_range_keys(Context, CursorOptions)).


%% @equiv load_modb(Context, View, [])
-spec load_modb(cb_context:context(), kz_term:ne_binary()) -> cb_context:context().
load_modb(Context, View) ->
    load_modb(Context, View, []).

%%------------------------------------------------------------------------------
%% @doc This function attempts to load the context with the results of a view
%% run against the account's MODBs.
%% @end
%%------------------------------------------------------------------------------

-spec load_modb(cb_context:context(), kz_term:ne_binary(), options()) -> cb_context:context().
load_modb(Context, View, Options) ->
    CursorOptions = build_cursor_options(Context, Options, 'true', 'true'),
    load_view(Context, View, [], build_modb_options(Context, CursorOptions)).


%% @equiv load_yodb(Context, View, [])
-spec load_yodb(cb_context:context(), kz_term:ne_binary()) -> cb_context:context().
load_yodb(Context, View) ->
    load_yodb(Context, View, []).

%%------------------------------------------------------------------------------
%% @doc This function attempts to load the context with the results of a view
%% run against the account's YODBs.
%% @end
%%------------------------------------------------------------------------------
-spec load_yodb(cb_context:context(), kz_term:ne_binary(), options()) -> cb_context:context().
load_yodb(Context, View, Options) ->
    CursorOptions = build_cursor_options(Context, Options, 'true', 'true'),
    load_view(Context, View, [], build_yodb_options(Context, CursorOptions)).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec find(cb_context:context(), kz_term:ne_binary(), kz_view:selector(), options()) -> cb_context:context().
find(Context, View, Selector, Options) ->
    CursorOptions = build_cursor_options(Context, Options, 'false', 'false'),
    load_view(Context, View, Selector, build_range_keys(Context, CursorOptions)).

%% build options funs {{{
%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec build_range_keys(cb_context:context(), kz_either:either(cb_context:context(), kz_view:options())) ->
          kz_either:either(cb_context:context(), kz_view:options()).
build_range_keys(Context, {'ok', CursorOptions}) ->
    Bookmark = props:get_value('bookmark', CursorOptions, []),
    case props:is_true('no_design_module', CursorOptions, 'true') of
        'false' ->
            {'ok', CursorOptions};
        'true' ->
            {StartKey, EndKey} = build_start_end_keys(Context, CursorOptions, props:get_value('direction', CursorOptions)),
            Prop = props:filter_undefined(
                     [{'startkey', StartKey}
                     ,{'endkey', EndKey}
                     ,{'startkey_docid', props:get_value('next_startkey_docid', Bookmark)}
                     ]),
            {'ok', props:set_values(Prop, props:delete('bookmark', CursorOptions))}
    end;
build_range_keys(_, {'error', _}=Error) ->
    Error.

-spec build_time_range_keys(cb_context:context(), kz_either:either(cb_context:context(), kz_view:options())) ->
          kz_either:either(cb_context:context(), kz_view:options()).
build_time_range_keys(_Context, {'ok', CursorOptions}) ->
    Bookmark = props:get_value('bookmark', CursorOptions, []),
    case props:is_true('no_design_module', CursorOptions, 'true') of
        'false' ->
            {'ok', CursorOptions};
        'true' ->
            {StartKey, EndKey} = build_time_start_end_keys(CursorOptions),
            Prop = props:filter_undefined(
                     [{'startkey', StartKey}
                     ,{'endkey', EndKey}
                     ,{'startkey_docid', props:get_value('next_startkey_docid', Bookmark)}
                     ]),
            {'ok', props:set_values(Prop, props:delete('bookmark', CursorOptions))}
    end;
build_time_range_keys(_, {'error', _}=Error) ->
    Error.

-spec build_modb_options(cb_context:context(), kz_either:either(cb_context:context(), kz_view:options())) ->
          kz_either:either(cb_context:context(), kz_view:options()).
build_modb_options(Context, Thing) ->
    case build_time_range_keys(Context, Thing) of
        {'ok', CursorOptions} ->
            {'ok', props:set_value('databases', get_range_modbs(Context, CursorOptions), CursorOptions)};
        {'error', _}=Error -> Error
    end.

-spec build_yodb_options(cb_context:context(), kz_either:either(cb_context:context(), kz_view:options())) ->
          kz_either:either(cb_context:context(), kz_view:options()).
build_yodb_options(Context, Thing) ->
    case build_time_range_keys(Context, Thing) of
        {'ok', CursorOptions} ->
            {'ok', props:set_value('databases', get_range_yodbs(Context, CursorOptions), CursorOptions)};
        {'error', _}=Error -> Error
    end.
%% }}}

%% old get_*_funs {{{
%%------------------------------------------------------------------------------
%% @doc Returns a function to get `doc' object from each view result.
%% @end
%%------------------------------------------------------------------------------
-spec get_doc_fun() -> mapper_fun().
get_doc_fun() -> fun(JObj, Acc) -> [kz_json:get_json_value(<<"doc">>, JObj)|Acc] end.

%%------------------------------------------------------------------------------
%% @doc Returns a function to get `value' object from each view result.
%% @end
%%------------------------------------------------------------------------------
-spec get_value_fun() -> mapper_fun().
get_value_fun() -> fun(JObj, Acc) -> [kz_json:get_value(<<"value">>, JObj)|Acc] end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec get_key_fun() -> mapper_fun().
get_key_fun() -> fun(JObj, Acc) -> [kz_json:get_value(<<"key">>, JObj)|Acc] end.

%%------------------------------------------------------------------------------
%% @doc Returns a function to get `value' object from each view result.
%% @end
%%------------------------------------------------------------------------------
-spec get_id_fun() -> mapper_fun().
get_id_fun() -> fun(JObj, Acc) -> [kz_doc:id(JObj)|Acc] end.
%% }}}

%% build kz_view:options {{{
%%%=============================================================================
%%% Build load view parameters internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec build_cursor_options(cb_context:context(), options(), boolean(), boolean()) ->
          kz_either:either(cb_context:context(), kz_view:options()).
build_cursor_options(Context, Options, NoDesignModule, IsTimeQuery) ->
    try
        CursorOptions = props:filter_undefined(
                          [{'batch_size', get_batch_size(Context, Options)}
                          ,{'bookmark', cb_context:req_value(Context, <<"bookmark">>, 'undefined')}
                          ,{'databases', props:get_value('databases', Options)}
                          ,{'direction', direction(Context, Options)}
                          ,{'key_min_length', props:get_value('key_min_length', Options)}
                          ,{'lager_prefix', "(crossbar)"}
                          ,{'memory_limit', kapps_config:get_integer(?CONFIG_CAT, <<"request_memory_limit">>)}
                          ,{'no_batch', kz_term:is_true(props:get_first_defined(['no_batch', 'unchunkable'], Options, 'false'))}
                          ,{'no_design_module', props:is_true('no_design_module', Options, NoDesignModule)}
                          ,{'page_size', get_page_size(Context, Options)}
                          ,{'verbose_log', 'true'}
                          ]),
        add_user_params(Context, CursorOptions, Options, IsTimeQuery)
    of
        {'ok', NewCursorOptions} ->
            {'ok', NewCursorOptions};
        {'error', Ctx} ->
            Ctx
    catch
        'throw':{'error', ErrorMsg} ->
            {'error', cb_context:add_system_error(404, 'faulty_request', ErrorMsg, Context)}
    end.

-spec add_user_params(cb_context:context(), kz_view:options(), options(), boolean()) ->
          kz_either:either(cb_context:context(), kz_view:options()).
add_user_params(Context, CursorOptions, Options, IsTimeQuery) ->
    TimeFilterKey = props:get_ne_binary_value('time_filter_key', Options, <<"created">>),
    HasQSFilter = has_qs_filter(Context, Options, TimeFilterKey, IsTimeQuery),
    UserMapper = props:get_value('mapper', Options),

    Prop = [{'has_qs_filter', HasQSFilter}
           ,{'is_chunked', is_chunked(Context, Options)}
           ,{'is_time_query', IsTimeQuery}
           ,{'should_paginate', cb_context:should_paginate(Context)}
           ,{'time_filter_key', TimeFilterKey}
           | [{K, V}
              || {K, V} <- add_fields_options(Context, Options),
                 lists:member(K, ?USER_PARAMS_ONLY)
             ]
           ],
    case time_range(Context, Options, TimeFilterKey) of
        {StartTime, EndTime} ->
            CursorProp = [{'filtermap', build_filtermap(Context, UserMapper, Prop)}
                         ,{'user_params', [{'start_time', StartTime}
                                          ,{'end_time', EndTime}
                                          | Prop
                                          ]
                          }
                         ],
            {'ok', merge_options(props:set_values(CursorProp, CursorOptions), Options)
            };
        Ctx -> {'error', Ctx}
    end.

-spec has_qs_filter(cb_context:context(), options(), kz_term:ne_binary(), boolean()) -> boolean().
has_qs_filter(Context, Options, TimeFilterKey, 'true') ->
    not props:is_true('no_filter', Options, 'false')
        andalso crossbar_filter:is_defined(Context)
        andalso not crossbar_filter:is_only_time_filter(Context, TimeFilterKey);
has_qs_filter(Context, Options, _, 'false') ->
    not props:is_true('no_filter', Options, 'false')
        andalso crossbar_filter:is_defined(Context).

-spec add_fields_options(cb_context:context(), options()) -> options().
add_fields_options(Context, Options) ->
    case kz_json:get_ne_binaries(<<"fields">>, cb_context:query_string(Context)) of
        [] ->
            [{'has_fields', 'false'}
            | Options
            ];
        Fields ->
            [{'fields', Fields}
            ,{'field_key', props:get_value('field_key', Options, <<"doc">>)}
            ,{'has_fields', not props:is_true('no_fields', Options, 'false')}
            | Options
            ]
    end.

build_filtermap(Context, UserMapper, UserParams) ->
    crossbar_filter:build_with_user_params(Context, UserParams, UserMapper).

-spec merge_options(kz_view:options(), options()) -> kz_view:options().
merge_options(CursorOptions, Options) ->
    %% remove result key in favor of crossbar_view mapper fun
    DeleteKeys = ['descending', 'limit', 'result_key'
                 | ?CB_SPECIFIC_VIEW_OPTIONS
                 ],
    DefaultOptions = props:set_values(CursorOptions, props:delete_keys(DeleteKeys, Options)),
    lists:foldl(fun(F, Acc) -> F(Acc) end
               ,DefaultOptions
               ,[fun maybe_set_include_docs/1
                ,fun maybe_set_log_prefix/1
                ]).

maybe_set_include_docs(Options) ->
    case props:is_true(['user_params', 'has_qs_filter'], Options, 'false')
        orelse (props:is_true(['user_params', 'has_fields'], Options, 'false')
                andalso props:get_value(['user_params', 'field_key'], Options) =:= <<"doc">>
               )
    of
        'true' -> ['include_docs' | props:delete('include_docs', Options)];
        'false' -> Options
    end.

maybe_set_log_prefix(Options) ->
    case props:is_true(['user_params', 'is_chunked'], Options) of
        'true' -> props:set_value('lager_prefix', "(chunked)", Options);
        'false' -> Options
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @equiv direction(Context, [])
%% @end
%%------------------------------------------------------------------------------
-spec direction(cb_context:context()) -> kz_view:direction().
direction(Context) ->
    direction(Context, []).

%%------------------------------------------------------------------------------
%% @doc Find view sort direction from `Options' or request
%% query string. Default to `descending'.
%% @end
%%------------------------------------------------------------------------------
-spec direction(cb_context:context(), kz_view:options() | options()) -> kz_view:direction().
direction(Context, Options) ->
    case props:get_value('direction', Options) =:= 'descending'
        orelse props:is_true('descending', Options, 'false')
        orelse kz_json:is_true(<<"descending">>, cb_context:query_string(Context))
        orelse kz_json:is_false(<<"ascending">>, cb_context:query_string(Context), 'true')
    of
        'true' -> 'descending';
        'false' -> 'ascending'
    end.

-spec get_batch_size(cb_context:context(), options()) -> kz_term:api_pos_integer().
get_batch_size(Context, Options) ->
    SystemSize = kapps_config:get_pos_integer(?CONFIG_CAT, <<"load_view_chunk_size">>, 50),
    OptionsSize = props:get_integer_value('batch_size', Options, SystemSize),

    case kz_json:get_first_defined([<<"batch_size">>, <<"chunk_size">>], cb_context:query_string(Context)) of
        'undefined' -> OptionsSize;
        Size ->
            try kz_term:to_integer(Size) of
                ChunkSize when ChunkSize > 0,
                               ChunkSize =< SystemSize ->
                    ChunkSize;
                ChunkSize when ChunkSize < 0 ->
                    throw({'error', <<"chunk size must be at least 1">>});
                ChunkSize when ChunkSize > SystemSize ->
                    throw({'error', <<"chunk size must be lower than ", (integer_to_binary(SystemSize))/binary>>})
            catch
                _:_ ->
                    throw({'error', <<"invalid chunk size">>})
            end
    end.

-spec is_chunked(cb_context:context(), options()) -> boolean().
is_chunked(Context, Options) ->
    kz_json:is_true(<<"is_chunked">>
                   ,cb_context:query_string(Context)
                   ,props:get_is_true('is_chunked', Options, 'false')
                   )
        andalso not props:get_is_true('unchunkable', Options, 'false').

%%------------------------------------------------------------------------------
%% @doc If pagination available, returns page size.
%%
%% <div class="notice">DO NOT ADD ONE (1) TO PAGE_SIZE OR LIMIT YOURSELF!
%% It will be added by this module during querying.</div>
%% If `paginate=false` is explicitly set, still load results in pages but check
%% process' memory usage on each page, terminating if memory exceeds a threshold
%% @end
%%------------------------------------------------------------------------------
-spec get_page_size(cb_context:context(), options()) -> kz_view:limit().
get_page_size(Context, Options) ->
    case props:is_true('should_paginate', Options, 'true')
        andalso cb_context:should_paginate(Context)
    of
        'true' ->
            case props:get_value('limit', Options) of
                'undefined' ->
                    get_page_size_from_request(Context);
                Limit ->
                    lager:debug("got limit from options: ~b", [Limit]),
                    Limit
            end;
        'false' ->
            lager:debug("pagination disabled in context or option"),
            'infinity'
    end.

-spec get_page_size_from_request(cb_context:context()) -> pos_integer().
get_page_size_from_request(Context) ->
    case cb_context:req_value(Context, <<"page_size">>) of
        'undefined' -> cb_context:pagination_page_size();
        Size ->
            try kz_term:to_integer(Size) of
                PageSize when PageSize > 0 -> PageSize;
                _ ->
                    throw({'error', <<"page size must be at least 1">>})
            catch
                _:_ ->
                    throw({'error', <<"invalid page size">>})
            end
    end.

%%------------------------------------------------------------------------------
%% @doc Create ranged view lookup database list using start/end time and
%% direction.
%% @end
%%------------------------------------------------------------------------------
-spec get_range_modbs(cb_context:context(), kz_view:options()) -> kz_term:ne_binaries().
get_range_modbs(Context, Options) ->
    Direction = props:get_value('direction', Options),
    StartTime = props:get_value(['user_params', 'start_time'], Options),
    EndTime = props:get_value(['user_params', 'end_time'], Options),
    case props:get_value('databases', Options) of
        'undefined' when Direction =:= 'ascending' ->
            kazoo_modb:get_range(cb_context:account_id(Context), StartTime, EndTime);
        'undefined' when Direction =:= 'descending' ->
            lists:reverse(kazoo_modb:get_range(cb_context:account_id(Context), StartTime, EndTime));
        Dbs when Direction =:= 'ascending' ->
            lists:usort(Dbs);
        Dbs when Direction =:= 'descending' ->
            lists:reverse(lists:usort(Dbs))
    end.

%%------------------------------------------------------------------------------
%% @doc Create ranged view lookup database list using start/end time and
%% direction.
%% @end
%%------------------------------------------------------------------------------
-spec get_range_yodbs(cb_context:context(), kz_view:options()) -> kz_term:ne_binaries().
get_range_yodbs(Context, Options) ->
    Direction = props:get_value('direction', Options),
    StartTime = props:get_value(['user_params', 'start_time'], Options),
    EndTime = props:get_value(['user_params', 'end_time'], Options),
    case props:get_value('databases', Options) of
        'undefined' when Direction =:= 'ascending' ->
            kazoo_yodb:get_range(cb_context:account_id(Context), StartTime, EndTime);
        'undefined' when Direction =:= 'descending' ->
            lists:reverse(kazoo_yodb:get_range(cb_context:account_id(Context), StartTime, EndTime));
        Dbs when Direction =:= 'ascending' ->
            lists:usort(Dbs);
        Dbs when Direction =:= 'descending' ->
            lists:reverse(lists:usort(Dbs))
    end.
%% }}}

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec load_view(cb_context:context(), kz_term:ne_binary(), kz_view:selector(), kz_either:either(cb_context:context(), kz_view:options())) ->
          cb_context:context().
load_view(_, _, _, {'error', Context}) ->
    Context;
load_view(Context, View, Selector, {'ok', Options}) ->
    case cb_context:fetch(Context, 'crossbar_view_extra') of
        'undefined' ->
            load_view({'ok', {Context, View, Selector, Options}});
        Fun ->
            load_view(Fun(Context, View, Selector, Options))
    end.

load_view({'ok', {Context, View, Selector, Options}}) ->
    [Database|_] = props:get_value('databases', Options, [cb_context:db_name(Context)]),
    HasQsfilter = props:is_true(['user_params', 'has_qs_filter'], Options),
    Setters = [{fun cb_context:set_doc/2, []}
              ,{fun cb_context:set_resp_data/2, []}
              ,{fun cb_context:set_resp_status/2, 'success'}
              ,{fun cb_context:store/3, 'has_qs_filter', HasQsfilter}
              ],
    IsChunked = props:is_true(['user_params', 'is_chunked'], Options),
    case kz_view:find_batch(Database, View, Selector, Options) of
        {'ok', Cursor} ->
            handle_load_view(cb_context:setters(Context, Setters), View, Cursor, IsChunked);
        {'error', Reason} ->
            crossbar_doc:handle_datamgr_errors(Reason, View, Context)
    end;
load_view({'error', Context}) ->
    Context.

handle_load_view(Context, _, Cursor, 'true') ->
    Setters = [{fun cb_context:store/3, 'is_chunked', 'true'}
              ,{fun cb_context:store/3, 'chunking_started', 'false'}
              ,{fun cb_context:store/3, 'view_cursor', Cursor}
              ],
    cb_context:setters(Context, Setters);
handle_load_view(Context, View, Cursor, 'false') ->
    case kz_view_cursor:next(Cursor) of
        {'ok', 'cursor_exhausted'} ->
            crossbar_doc:handle_datamgr_success([], Context);
        {'ok', {NewCursor, JObjs}} ->
            Envelope = kz_json:set_values(kz_view_cursor:bookmark_compat(NewCursor), cb_context:resp_envelope(Context)),
            crossbar_doc:handle_datamgr_success(JObjs, cb_context:set_resp_envelope(Context, Envelope));
        {'error', Reason} ->
            lager:debug("cursor failed: ~p", [Reason]),
            crossbar_doc:handle_datamgr_errors(Reason, View, Context)
    end.

-spec next_batch(cb_context:context(), kz_view_cursor:cursor()) ->
          kz_either:either(cb_context:context(), {kz_view_cursor:cursor(), kz_view:result_value()} | 'cursor_exhausted').
next_batch(Context, Cursor) ->
    #{design_view := View} = kz_view_cursor:get_driver_params(Cursor),
    case kz_view_cursor:next_batch(Cursor) of
        {'ok', _}=OK -> OK;
        {'error', Reason} ->
            lager:debug("cursor failed: ~p", [Reason]),
            {'error', crossbar_doc:handle_datamgr_errors(Reason, View, Context)}
    end.

%% start/end, range keys {{{
%%------------------------------------------------------------------------------
%% @doc Suffix the Timestamp to the provided key map option. Useful to use
%% generate the keys like `[Timestamp, InteractionId]' for the end key in
%% {@link cb_cdrs} for example.
%% @end
%%------------------------------------------------------------------------------
-spec suffix_key_fun(range_keymap()) -> range_keymap_fun().
suffix_key_fun('nil') -> fun(_) -> 'undefined' end;
suffix_key_fun('undefined') -> fun kz_term:identity/1;
suffix_key_fun(['undefined']) -> fun kz_term:identity/1;
suffix_key_fun(K) when is_binary(K) -> fun(Ts) -> [Ts, K] end;
suffix_key_fun(K) when is_integer(K) -> fun(Ts) -> [Ts, K] end;
suffix_key_fun(K) when is_list(K) -> fun(Ts) -> [Ts | K] end;
suffix_key_fun(K) when is_function(K, 1) -> K.

%%------------------------------------------------------------------------------
%% @doc Returns a time range for range query based or payload on request or `Options'
%% and default range based on system configuration (maximum range).
%%
%% The start time, `created_from' (default), should always be prior to end time
%% `created_to'.
%%
%% <strong>Options:</strong>
%% <dl>
%%   <dt>`max_range'</dt><dd>Maximum range allowed. Default is the value of
%%   `crossbar.maximum_range', 31 days.</dd>
%%
%%   <dt>`range_key'</dt><dd>The key name in query string to get values
%%   from (created, modified or ...). Default is `created'.</dd>
%%
%%   <dt>`{RANGE_KEY}_from'</dt><dd>Start time.</dd>
%%
%%   <dt>`{RANGE_KEY}_to'</dt><dd>End time.</dd>
%% </dl>
%% @private
%% @end
%%------------------------------------------------------------------------------
-spec time_range(cb_context:context(), options(), kz_term:ne_binary()) -> time_range() | cb_context:context().
time_range(Context, Options, Key) ->
    MaxRange = get_max_range(Options),
    TSTime = kz_time:now_s(),
    RangeTo = get_time_key(Context, <<Key/binary, "_to">>, Options, TSTime),
    RangeFrom = get_time_key(Context, <<Key/binary, "_from">>, Options, RangeTo - MaxRange),
    time_range(Context, MaxRange, Key, RangeFrom, RangeTo).

%%------------------------------------------------------------------------------
%% @doc Get time key value from options or request.
%% @end
%%------------------------------------------------------------------------------
-spec get_time_key(cb_context:context(), kz_term:ne_binary(), options(), pos_integer()) -> pos_integer().
get_time_key(Context, Key, Options, Default) ->
    case props:get_integer_value(Key, Options) of
        'undefined' ->
            case kz_term:safe_cast(cb_context:req_value(Context, Key), Default, fun kz_term:to_integer/1) of
                T when T > 0 -> T;
                _ -> Default
            end;
        Value -> Value
    end.

%%------------------------------------------------------------------------------
%% @doc Get `max_range' from option or system config.
%% @end
%%------------------------------------------------------------------------------
-spec get_max_range(options()) -> pos_integer().
get_max_range(Options) ->
    case props:get_integer_value('max_range', Options) of
        'undefined' -> ?MAX_RANGE;
        MaxRange -> MaxRange
    end.

%%------------------------------------------------------------------------------
%% @doc Checks whether or not end time is prior to start time. Returns a ranged
%% tuple `{start_time, end_time}' or `context' with validation error.
%% @end
%%------------------------------------------------------------------------------
-spec time_range(cb_context:context(), pos_integer(), kz_term:ne_binary(), pos_integer(), pos_integer()) ->
          time_range() | cb_context:context().
time_range(Context, MaxRange, Key, RangeFrom, RangeTo) ->
    Path = <<Key/binary, "_from">>,
    case RangeTo - RangeFrom of
        N when N < 0 ->
            Msg = kz_term:to_binary(io_lib:format("~s_to ~b is prior to ~s ~b", [Key, RangeTo, Path, RangeFrom])),
            JObj = kz_json:from_list([{<<"message">>, Msg}, {<<"cause">>, RangeFrom}]),
            lager:debug("range error: ~s", [Msg]),
            cb_context:add_validation_error(Path, <<"date_range">>, JObj, Context);
        N when N > MaxRange ->
            Msg = kz_term:to_binary(io_lib:format("~s_to ~b is more than ~b seconds from ~s ~b", [Key, RangeTo, MaxRange, Path, RangeFrom])),
            JObj = kz_json:from_list([{<<"message">>, Msg}, {<<"cause">>, RangeTo}]),
            lager:debug("range_error: ~s", [Msg]),
            cb_context:add_validation_error(Path, <<"date_range">>, JObj, Context);
        _ ->
            {RangeFrom, RangeTo}
    end.

%%------------------------------------------------------------------------------
%% @doc Returns start/end keys based on direction.
%% Returned tuple is `{start_key, end_key}'.
%%
%% If `start_key' is present in the request (query string or payload)
%% they will be returned instead. Otherwise the keys will built by key map options.
%%
%% <strong>Options description:</strong>
%% <dl>
%%   <dt>`keymap'</dt><dd>Use this to map both start/end keys.</dd>
%%   <dt>`start_keymap'</dt><dd>Maps start key only.</dd>
%%   <dt>`end_keymap'</dt><dd>Maps end key only.</dd>
%% </dl>
%%
%% See also {@link direction/2} for `direction' option explanation.
%%
%% <strong>Keymap description:</strong>
%% <dl>
%%   <dt>{@type kazoo_data:range_key()}</dt><dd>A regular CouchDB key to construct
%%    keys like `[<<"en">>, <<"us">>]'.</dd>
%%   <dt>{@type keymap_fun()}</dt><dd>To customize your own key using a function.</dd>
%% </dl>
%%
%% The keys will be swapped if direction is descending.
%% @see direction/2
%% @private
%% @end
%%------------------------------------------------------------------------------
-spec build_start_end_keys(cb_context:context(), kz_view:options(), kz_view:direction()) -> range_keys().
build_start_end_keys(Context, Options, Direction) ->
    {StartKey, EndKey} = build_start_end_keys(Context, Options),
    case props:get_value(['bookmark', 'next_startkey'], Options) of
        'undefined' when Direction =:= 'ascending' ->
            {StartKey, EndKey};
        'undefined' when Direction =:= 'descending' ->
            {EndKey, StartKey};
        NextStartKey when Direction =:= 'ascending' ->
            {NextStartKey, EndKey};
        NextStartKey when Direction =:= 'descending' ->
            {NextStartKey, StartKey}
    end.

%%------------------------------------------------------------------------------
%% @doc Build customized start/end key mapper.
%% @end
%%------------------------------------------------------------------------------
-spec build_start_end_keys(cb_context:context(), kz_view:options()) -> {api_range_key(), api_range_key()}.
build_start_end_keys(Context, Options) ->
    UserParams = props:get_value('user_params', Options),
    KeyMap = props:get_value('keymap', UserParams),
    {maybe_keymap(Context, Options, KeyMap, 'startkey', 'start_keymap')
    ,maybe_keymap(Context, Options, KeyMap, 'endkey', 'end_keymap')
    }.

maybe_keymap(Context, Options, 'undefined', Key, KeyKeymap) ->
    UserParams = props:get_value('user_params', Options),
    map_keymap(Context, Options, props:get_value(Key, Options, props:get_value(KeyKeymap, UserParams)));
maybe_keymap(Context, Options, KeyMap, _, _) ->
    map_keymap(Context, Options, KeyMap).

-spec map_keymap(cb_context:context(), options(), keymap()) -> api_range_key().
map_keymap(Context, _, Fun) when is_function(Fun, 1) -> Fun(Context) ;
map_keymap(Context, Options, Fun) when is_function(Fun, 2) -> Fun(Options, Context);
map_keymap(_, _, ApiRangeKey) -> ApiRangeKey.

%%------------------------------------------------------------------------------
%% @doc Returns start/end keys based on direction. Start/end timestamp will be
%% added to keys based on requested time range.
%% Returned tuple is `{start_key, end_key}'.
%%
%% If `start_key' is present in the request (query string or payload)
%% they will be returned instead. Otherwise the keys will built by key map options.
%%
%% <strong>Options description:</strong>
%% <dl>
%%   <dt>`range_keymap'</dt><dd>Use this to map both start/end keys.</dd>
%%   <dt>`range_start_keymap'</dt><dd>maps start key only.</dd>
%%   <dt>`range_end_keymap'</dt><dd>maps end key only.</dd>
%% </dl>
%%
%% See also {@link direction/2} and {@link time_range/2} for explanation of
%% other options.
%%
%% <strong>Keymap description:</strong>
%% <dl>
%%   <dt>{@type kz_term:ne_binary()}</dt><dd>Constructs keys like `[<<"account">>, Timestamp]'.</dd>
%%   <dt>{@type integer()}</dt><dd>Constructs keys like `[1234, Timestamp]'.</dd>
%%   <dt>{@type list()}</dt><dd>Constructs keys like `[<<"en">>, <<"us">>, Timestamp]'.</dd>
%%   <dt>{@type range_keymap_fun()}</dt><dd>Customize your own key using a function.</dd>
%% </dl>
%%
%% The keys will be swapped if direction is descending.
%% @private
%% @end
%%------------------------------------------------------------------------------
-spec build_time_start_end_keys(kz_view:options()) -> range_keys().
build_time_start_end_keys(CursorOptions) ->
    Direction = props:get_value('direction', CursorOptions),

    UserParams = props:get_value('user_params', CursorOptions, CursorOptions),
    StartTime = props:get_value('start_time', UserParams),
    EndTime = props:get_value('end_time', UserParams),

    {StartKeyMap, EndKeyMap} = build_time_range_keymaps_fun(CursorOptions),
    case props:get_value(['bookmark', 'next_startkey'], CursorOptions) of
        'undefined' when Direction =:= 'ascending' ->
            {StartKeyMap(StartTime), EndKeyMap(EndTime)};
        'undefined' when Direction =:= 'descending' ->
            {EndKeyMap(EndTime), StartKeyMap(StartTime)};
        NextStartKey when Direction =:= 'ascending' ->
            {NextStartKey, EndKeyMap(EndTime)};
        NextStartKey when Direction =:= 'descending' ->
            {NextStartKey, StartKeyMap(StartTime)}
    end.

%%------------------------------------------------------------------------------
%% @doc See {@link build_time_start_end_keys/2} for explaining of options and range_keymap.
%% @end
%%------------------------------------------------------------------------------
-spec build_time_range_keymaps_fun(kz_view:options()) -> {range_keymap_fun(), range_keymap_fun()}.
build_time_range_keymaps_fun(Options) ->
    UserParams = props:get_value('user_params', Options),
    case props:get_value('range_keymap', UserParams) of
        'undefined' ->
            {map_range_keymap(props:get_value('startkey', Options, props:get_value('range_start_keymap', UserParams)))
            ,map_range_keymap(props:get_value('endkey', Options, props:get_value('range_end_keymap', UserParams)))
            };
        KeyMap -> {map_range_keymap(KeyMap), map_range_keymap(KeyMap)}
    end.

-spec map_range_keymap(range_keymap()) -> range_keymap_fun().
map_range_keymap('nil') -> fun(_) -> 'undefined' end;
map_range_keymap('undefined') -> fun kz_term:identity/1;
map_range_keymap(['undefined']) -> fun(Ts) -> [Ts] end;
map_range_keymap(K) when is_binary(K) -> fun(Ts) -> [K, Ts] end;
map_range_keymap(K) when is_integer(K) -> fun(Ts) -> [K, Ts] end;
map_range_keymap(K) when is_list(K) -> fun(Ts) -> K ++ [Ts] end;
map_range_keymap(K) when is_function(K, 1) -> K.
%% }}}
