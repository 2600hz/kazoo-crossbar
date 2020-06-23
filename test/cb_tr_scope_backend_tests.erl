%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2012-2020, 2600Hz
%%% @doc
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cb_tr_scope_backend_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("kazoo_auth/include/kz_auth_scope.hrl").
-include("cb_token_restrictions_test.hrl").

-define(TR_READ, [?HTTP_GET]).
-define(TR_DENY, []).
-define(TR_WRITE, lists:sort([?HTTP_PUT, ?HTTP_POST, ?HTTP_PATCH, ?HTTP_DELETE])).
-define(TR_MIXED_PRIVS, lists:sort([?HTTP_PUT, ?HTTP_PATCH, ?HTTP_DELETE, ?HTTP_GET])).
-define(TR_MIXED_WRITE, lists:sort([?HTTP_PUT, ?HTTP_PATCH, ?HTTP_DELETE])).
-define(TR_FULL_CONTROL, lists:sort(?TR_READ ++ ?TR_WRITE)).

-define(DEVICES_BASIC(Verbs)
       ,{<<"devices">>
           ,[kz_json:from_list(
               [{<<"rules">>, kz_json:from_list([{?ARGS_ANY, Verbs}])}]
              )
            ]
           }         
       ).

-define(DEVICES_PROPS(Verbs)
       ,{<<"devices">>
           ,[kz_json:from_list(
               [{<<"allowed_accounts">>, ?ACCOUNTS_ANY}
               ,{<<"rules">>, kz_json:from_list([{?ARGS_ANY, Verbs}])}]
              )
            ]
           }         
       ).

-define(USERS_BASIC(Verbs)
       ,{<<"users">>
           ,[kz_json:from_list(
               [{<<"rules">>, kz_json:from_list([{?ARGS_ANY, Verbs}])}]
              )
            ]
           }        
       ).

-define(RO_GLOBAL
       ,kz_json:from_list(
          [{?CATCH_ALL
           ,[kz_json:from_list(
               [{<<"rules">>, kz_json:from_list([{?ARGS_ANY, [?HTTP_GET]}])}]
              )
            ]
           }
          ]
         )
       ).

-define(RO_SCOPES_ONLY
	   ,kz_json:from_list(
          [?DEVICES_BASIC(?TR_READ)
          ,?USERS_BASIC(?TR_READ)
          ]
         ) 					  
	   ).

-define(RW_SCOPES_ONLY(Verbs)
	   ,kz_json:from_list(
          [?DEVICES_BASIC(Verbs)
          ,?USERS_BASIC(Verbs)
          ]
         ) 					  
	   ).

-define(TR_BASIC(Verbs)
	   ,kz_json:from_list(
          [?USERS_BASIC(Verbs)
          ,?DEVICES_BASIC(Verbs)
          ]
         )	 					  
	   ).

-define(SCOPES
	   ,kz_auth_scope:parse_raw(<<"devices users">>) 
	   ).

-define(SCOPES_W
	   ,kz_auth_scope:parse_raw(<<"devices:write users:write">>) 
	   ).

verbs_test_() ->
	[{"Basic Read Only Verb Test."
	 ,?_assertEqual(cb_tr_scope_backend:priv_to_verbs(?READ), ?TR_READ)
	 }
	,{"Basic Write Only Verb Test."
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:priv_to_verbs(?WRITE)), ?TR_WRITE)
	 }
	,{"Basic Full Control Verb Test."
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:priv_to_verbs(?FULL_CONTROL)), ?TR_FULL_CONTROL)
	 }
	].

restrictions_merge_test_() ->
	[{"Basic Read Only Restriction Test."
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?READ), ?TR_READ))
	 															,?TR_READ
	 															)
	 }
	,{"Basic Write Only Restriction Test."
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?WRITE), ?TR_WRITE))
	 															,?TR_WRITE
	 															)
	 }
	,{"Basic Full Control Restriction Test."
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?FULL_CONTROL), ?TR_FULL_CONTROL))	
	 															,?TR_FULL_CONTROL
	 															)
	 }
	,{"Mixed Read/Write Restrictions Test"
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?FULL_CONTROL), ?TR_MIXED_PRIVS))	
	 															,?TR_MIXED_PRIVS
	 															)
	 }
	,{"Mixed Read/Write Restrictions Read Only Test"
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?READ), ?TR_MIXED_PRIVS))	
	 															,?TR_READ
	 															)
	 }
	,{"Mixed Read/Write Restrictions Write Only Test"
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?WRITE), ?TR_MIXED_PRIVS))	
	 															,?TR_MIXED_WRITE
	 															)
	 }
	,{"Mixed Read/Write Restrictions Deny Test"
	 ,?_assertEqual(lists:sort(cb_tr_scope_backend:calc_allowed_methods(cb_tr_scope_backend:priv_to_verbs(?WRITE), ?TR_DENY))	
	 															,?TR_DENY
	 															)
	 }
	].

readonly_test_() ->
	[{"read only - no user scopes or defined restrictions"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only([], 'undefined', 'true'), ?RO_GLOBAL) 
	 }
	,{"read only - no user scopes with token restrictions"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only([], ?TR_BASIC(?TR_MIXED_PRIVS), 'true'), ?RO_SCOPES_ONLY) 
	 }
	,{"read only - user scopes undefined restrictions"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only(?SCOPES, 'undefined', 'true'), ?RO_SCOPES_ONLY) 
	 }
	,{"read only - merge basic token restrictions"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only(?SCOPES, ?TR_BASIC(?TR_MIXED_PRIVS), 'true'), ?RO_SCOPES_ONLY)
	 }
	,{"read only - merge token restrictions with props"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only(kz_auth_scope:parse_raw(<<"devices">>), ?ALLOW_API_ENDPOINT_RESTRICTIONS, 'true'), kz_json:from_list([?DEVICES_PROPS(?TR_READ)]))
	 }	
	].

privileges_test_() ->	
	[{"privileges - no user scopes or defined restrictions"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only([], 'undefined', 'false'), 'undefined') 
	 }	
	,{"privileges - user scope merge with privileges"
	 ,?_assertEqual(cb_tr_scope_backend:maybe_set_read_only(?SCOPES_W, ?RW_SCOPES_ONLY([?HTTP_GET, ?HTTP_PATCH]), 'false'), ?RW_SCOPES_ONLY([?HTTP_PATCH])) 
	 }
	].

