%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2012-2020, 2600Hz
%%% @doc
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_tr_scope_backend).
-behaviour(kz_scope_backend).

-include("crossbar.hrl").
-include_lib("kazoo_auth/include/kz_auth_scope.hrl").

-export([get_scope_restrictions/1
        ]).

-ifdef (TEST).
-export([calc_allowed_methods/2
        ,priv_to_verbs/1
        ,maybe_set_read_only/3
        ]).
-endif.

-define(CATCHALL, <<"_">>).
-define(ARGS_ANY, <<"#">>).
-define(ARGS_SINGLE, <<"*">>).
-define(RULES, <<"rules">>).

%% Filter out known non API scopes
-define(IGNORE_SCOPES, ?OIDC_SCOPES ++ ?SYS_SCOPES).
%% permission sets
-define(READ_ACCESS, [?HTTP_GET]).
-define(WRITE_ACCESS, [?HTTP_PUT, ?HTTP_POST, ?HTTP_DELETE, ?HTTP_PATCH]).
-define(ALL_ACCESS, ?READ_ACCESS ++ ?WRITE_ACCESS).
-define(DENY_ACCESS, []).

%% default scope -> restriction constants
-define(GLOBAL_READ_ONLY, kz_json:from_list([{?ARGS_ANY, ?READ_ACCESS}])).
-define(GLOBAL_FULL_CONTROL, kz_json:from_list([{?ARGS_ANY, ?ALL_ACCESS}])).

%%------------------------------------------------------------------------------
%% @doc Fetch subset of token restrictions based on scopes
%% @end
%%------------------------------------------------------------------------------
-spec get_scope_restrictions(kz_term:api_object()) -> kz_term:api_object().
get_scope_restrictions(AuthDoc) ->
    TokenRestrictions = crossbar_util:get_token_restrictions(kz_json:get_ne_value(<<"method">>, AuthDoc)
                                                            ,kz_json:get_ne_value(<<"account_id">>, AuthDoc)
                                                            ,kz_json:get_ne_value(<<"owner_id">>, AuthDoc)
                                                            ),
    resolve_restrictions(AuthDoc, TokenRestrictions).

%%------------------------------------------------------------------------------
%% @doc Fetch current auth doc token restrictions
%% @end
%%------------------------------------------------------------------------------
-spec resolve_restrictions(kz_term:api_object(), kz_term:api_object()) -> kz_term:api_object().
resolve_restrictions(AuthDoc, TokenRestrictions) ->
    PrivLevel = kz_json:get_ne_value(<<"priv_level">>, AuthDoc),
    RawScopes = kz_json:get_ne_value(<<"scope">>, AuthDoc),
    Filtered = kz_auth_scope:bin_to_list(RawScopes) -- ?IGNORE_SCOPES,
    Scopes = kz_auth_scope:parse_raw(Filtered, PrivLevel),
    maybe_set_read_only(Scopes, TokenRestrictions, kz_json:get_ne_value(?READ_ONLY, AuthDoc)).

%%------------------------------------------------------------------------------
%% @doc Verify if _read_only claim is set
%% @end
%%------------------------------------------------------------------------------
-spec maybe_set_read_only(scopes(), kz_term:api_object(), boolean()) -> kz_term:api_object().
maybe_set_read_only(Scopes, TokenRestrictions, 'true') ->
    set_read_only(Scopes, TokenRestrictions);
maybe_set_read_only(Scopes, TokenRestrictions, _ReadOnly) ->
    maybe_merge_scopes(Scopes, TokenRestrictions).

%%------------------------------------------------------------------------------
%% @doc Override merge if global read_only scope enabled
%% @end
%%------------------------------------------------------------------------------
-spec set_read_only(scopes(), kz_term:api_object()) -> kz_term:api_object().
set_read_only([], 'undefined') ->
    build_global_rule(?CATCHALL, ?GLOBAL_READ_ONLY);
set_read_only([], TokenRestrictions) ->
    Fun = fun(K, _V, Acc) ->
                  maybe_merge_scope_restrictions(K, TokenRestrictions, ?READ_ACCESS, Acc)
          end,
    Restrictions = kz_json:foldl(Fun , [], TokenRestrictions),
    kz_json:from_list(Restrictions);
set_read_only(Scopes, 'undefined') ->
    set_read_only(Scopes, build_global_rule(?CATCHALL, ?GLOBAL_READ_ONLY));
set_read_only(Scopes, TokenRestrictions) ->
    Fun = fun(S, Acc) ->
                  maybe_merge_scope_restrictions(S, TokenRestrictions, ?READ_ACCESS, Acc)
          end,
    Restrictions = lists:foldl(Fun , [], Scopes),
    kz_json:from_list(Restrictions).

%%------------------------------------------------------------------------------
%% @doc attempt to merge scope(s) with any defined token restrictions
%% @end
%%------------------------------------------------------------------------------
-spec maybe_merge_scopes(scopes(), kz_term:api_object()) -> kz_term:api_object().
maybe_merge_scopes([], 'undefined') ->
    lager:debug("no api scopes defined, applying token restrictions"),
    'undefined';
maybe_merge_scopes([], TokenRestrictions) ->
    TokenRestrictions;
maybe_merge_scopes(Scopes, 'undefined') ->
    lager:debug("api scopes defined, token restrictions 'undefined'"),
    maybe_merge_scopes(Scopes, build_global_rule(?CATCHALL, ?GLOBAL_FULL_CONTROL));
maybe_merge_scopes(Scopes, TokenRestrictions) ->
    lager:debug("no api scopes defined, applying defined token restrictions"),
    Fun = fun(S, Acc) ->
                  maybe_merge_scope_restrictions(S, TokenRestrictions, Acc)
          end,
    Restrictions = lists:foldl(Fun, [], Scopes),
    kz_json:from_list(Restrictions).


%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec maybe_merge_scope_restrictions(scope(), kz_term:api_object(), list()) -> list().
maybe_merge_scope_restrictions(#scope{privileges=Priv}=Scope, TokenRestrictions, Acc) ->
    Requested = priv_to_verbs(Priv),
    maybe_merge_scope_restrictions(Scope, TokenRestrictions, Requested, Acc).

-spec maybe_merge_scope_restrictions(scope() | kz_term:binary(), kz_term:api_object(), kz_term:binaries(), list()) -> list().
maybe_merge_scope_restrictions(#scope{scope=Name}, TokenRestrictions, Requested, Acc) ->
    maybe_merge_scope_restrictions(Name, TokenRestrictions, Requested, Acc);
maybe_merge_scope_restrictions(Name, TokenRestrictions, Requested, Acc) ->
    ResourceRestrictions = kz_json:get_first_defined([Name
                                                     ,?CATCHALL
                                                     ]
                                                    ,TokenRestrictions
                                                    ),
    Merged = merge_scope_restrictions(Name, ResourceRestrictions, Requested),
    [Merged | Acc].

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec merge_scope_restrictions(kz_term:binary(), kz_term:api_object(), kz_term:binaries()) -> kz_term:api_object().
                                                % merge_scope_restrictions(#scope{scope=Name}, ResourceRestrictions, Requested) ->
                                                %   merge_scope_restrictions(Name, ResourceRestrictions, Requested);
merge_scope_restrictions(Name, ResourceRestrictions, Requested) ->
    Fun = fun(Props, _Acc) ->
                  Mutator = fun(K, V, A) ->
                                    merge_restrictions(K, V, Requested, A)
                            end,
                  New = kz_json:foldl(Mutator, kz_json:new(), Props),
                  {Name, [New]}
          end,
    lists:foldl(Fun, [], ResourceRestrictions).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec merge_restrictions(kz_term:binary(), kz_term:api_objects(), kz_term:binaries(), kz_term:api_object()) -> kz_term:api_object().
merge_restrictions(?RULES, Resources, Requested, Acc) ->
    Fun = fun(K, V, A) ->
                  New = calc_allowed_methods(Requested, V),
                  build_rule_jobj(K, New, A)
          end,
    kz_json:foldl(Fun, Acc, Resources);
merge_restrictions(Key, Value, _Requested, Acc) ->
    kz_json:set_value(Key, Value, Acc).

%%------------------------------------------------------------------------------
%% @doc Calculate intersection of allowed methods
%% @end
%%------------------------------------------------------------------------------
-spec calc_allowed_methods(kz_term:binaries(),  kz_term:binaries()) -> kz_term:binaries().
calc_allowed_methods(ScopeRestrictions, [?CATCHALL]) ->
    calc_allowed_methods(ScopeRestrictions, ?ALL_ACCESS);
calc_allowed_methods(ScopeRestrictions, TokenRestrictions) ->
    sets:to_list(sets:intersection(sets:from_list(ScopeRestrictions)
                                  ,sets:from_list(TokenRestrictions)
                                  )
                ).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec build_global_rule(kz_term:binary(), kz_term:api_object()) -> kz_term:api_object().
build_global_rule(Pattern, Rules) ->
    Props = [{Pattern
             ,[[{<<"rules">>, Rules}]]
             }
            ],
    kz_json:from_list_recursive(Props).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec build_rule_jobj(kz_term:binary(), kz_term:binaries(), kz_term:api_object()) -> kz_term:api_object().
build_rule_jobj(Resource, Perms, JObj) ->
    kz_json:set_value(<<"rules">>, kz_json:from_list([{Resource, Perms}]), JObj).

%%------------------------------------------------------------------------------
%% @doc convert scope priviege to http verb set
%% @end
%%------------------------------------------------------------------------------
-spec priv_to_verbs(scope_priv()) -> kz_term:binaries().
priv_to_verbs('undefined') -> priv_to_verbs(?FULL_CONTROL);
priv_to_verbs(?READ) -> ?READ_ACCESS;
priv_to_verbs(?WRITE) -> ?WRITE_ACCESS;
priv_to_verbs(?FULL_CONTROL) -> ?ALL_ACCESS;
priv_to_verbs(_) -> priv_to_verbs('undefined').
