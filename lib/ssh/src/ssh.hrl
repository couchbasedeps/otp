%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2004-2017. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%

%%

%%
%% SSH definitions
%%

-ifndef(SSH_HRL).
-define(SSH_HRL, 1).

-define(SSH_DEFAULT_PORT, 22).
-define(SSH_MAX_PACKET_SIZE, (256*1024)).
-define(REKEY_TIMOUT, 3600000).
-define(REKEY_DATA_TIMOUT, 60000).
-define(DEFAULT_PROFILE, default).

-define(DEFAULT_TRANSPORT,  {tcp, gen_tcp, tcp_closed} ).

-define(DEFAULT_SHELL, {shell, start, []} ).

-define(MAX_RND_PADDING_LEN, 15).

-define(SUPPORTED_AUTH_METHODS, "publickey,keyboard-interactive,password").

-define(FALSE, 0).
-define(TRUE,  1).
%% basic binary constructors
-define(BOOLEAN(X),  (X):8/unsigned-big-integer).
-define(BYTE(X),     (X):8/unsigned-big-integer).
-define(UINT16(X),   (X):16/unsigned-big-integer).
-define(UINT32(X),   (X):32/unsigned-big-integer).
-define(UINT64(X),   (X):64/unsigned-big-integer).
-define(STRING(X),   ?UINT32((size(X))), (X)/binary).

-define(DEC_BIN(X,Len),   ?UINT32(Len), X:Len/binary ).
-define(DEC_MPINT(I,Len), ?UINT32(Len), I:Len/big-signed-integer-unit:8 ).

%% building macros
-define(boolean(X),
	case X of
	    true -> <<?BOOLEAN(1)>>;
	    false -> (<<?BOOLEAN(0)>>)
	end).

-define(byte(X),   << ?BYTE(X) >> ).
-define(uint16(X), << ?UINT16(X) >> ).
-define(uint32(X), << ?UINT32(X) >> ).
-define(uint64(X), << ?UINT64(X) >> ).
-define(string_utf8(X), << ?STRING(unicode:characters_to_binary(X)) >> ).
-define(string(X), ?string_utf8(X)).
-define(binary(X), << ?STRING(X) >>).

%% Cipher details
-define(SSH_CIPHER_NONE, 0).
-define(SSH_CIPHER_3DES, 3).
-define(SSH_CIPHER_AUTHFILE, ?SSH_CIPHER_3DES).

%% Option access macros
-define(do_get_opt(C,K,O),   ssh_options:get_value(C,K,O,  ?MODULE,?LINE)).
-define(do_get_opt(C,K,O,D), ssh_options:get_value(C,K,O,?LAZY(D),?MODULE,?LINE)).

-define(LAZY(D), fun()-> D end).

-define(GET_OPT(Key,Opts),              ?do_get_opt(user_options,    Key,Opts    ) ).
-define(GET_OPT(Key,Opts,Def),          ?do_get_opt(user_options,    Key,Opts,Def) ).
-define(GET_INTERNAL_OPT(Key,Opts),     ?do_get_opt(internal_options,Key,Opts    ) ).
-define(GET_INTERNAL_OPT(Key,Opts,Def), ?do_get_opt(internal_options,Key,Opts,Def) ).
-define(GET_SOCKET_OPT(Key,Opts),       ?do_get_opt(socket_options,  Key,Opts    ) ).
-define(GET_SOCKET_OPT(Key,Opts,Def),   ?do_get_opt(socket_options,  Key,Opts,Def) ).

-define(do_put_opt(C,KV,O),  ssh_options:put_value(C,KV,O, ?MODULE,?LINE)).

-define(PUT_OPT(KeyVal,Opts),           ?do_put_opt(user_options,    KeyVal,Opts) ).
-define(PUT_INTERNAL_OPT(KeyVal,Opts),  ?do_put_opt(internal_options,KeyVal,Opts) ).
-define(PUT_SOCKET_OPT(KeyVal,Opts),    ?do_put_opt(socket_options,  KeyVal,Opts) ).

-define(do_del_opt(C,K,O),  ssh_options:delete_key(C,K,O, ?MODULE,?LINE)).
-define(DELETE_INTERNAL_OPT(Key,Opts),  ?do_del_opt(internal_options,Key,Opts) ).


%% Types
-type role()                :: client | server .
-type ok_error(SuccessType) :: {ok, SuccessType} | {error, any()} .
-type daemon_ref()          :: pid() .

-type subsystem_spec()      :: {subsystem_name(), {channel_callback(), channel_init_args()}} .
-type subsystem_name()      :: string() .
-type channel_callback()    :: atom() .
-type channel_init_args()   :: list() .

-type algs_list()           :: list( alg_entry() ).
-type alg_entry()           :: {kex, simple_algs()} 
                             | {public_key, simple_algs()}
                             | {cipher, double_algs()}
                             | {mac, double_algs()}
                             | {compression, double_algs()} .
-type simple_algs()         :: list( atom() ) .
-type double_algs()         :: list( {client2server,simple_algs()} | {server2client,simple_algs()} )
                             | simple_algs() .

-type options() :: #{socket_options   := socket_options(),
                     internal_options := internal_options(),
                     option_key()     => any()
                    }.

-type socket_options()   :: proplists:proplist().
-type internal_options() :: #{option_key() => any()}.

-type option_key() :: atom().



%% Records
-record(ssh,
	{
	  role :: client | role(),
	  peer :: undefined | 
                  {inet:hostname(),
                   {inet:ip_address(),inet:port_number()}},         %% string version of peer address 

	  c_vsn,        %% client version {Major,Minor}
	  s_vsn,        %% server version {Major,Minor}

	  c_version,    %% client version string
	  s_version,    %% server version string

	  c_keyinit,    %% binary payload of kexinit packet
	  s_keyinit,    %% binary payload of kexinit packet

          send_ext_info, %% May send ext-info to peer
          recv_ext_info, %% Expect ext-info from peer

	  algorithms,   %% #alg{}
	  
	  kex,          %% key exchange algorithm
	  hkey,         %% host key algorithm
	  key_cb,       %% Private/Public key callback module
	  io_cb,        %% Interaction callback module

	  send_mac = none, %% send MAC algorithm
	  send_mac_key,  %% key used in send MAC algorithm
	  send_mac_size = 0,

	  recv_mac = none, %% recv MAC algorithm
	  recv_mac_key,  %% key used in recv MAC algorithm
	  recv_mac_size = 0,

	  encrypt = none,       %% encrypt algorithm
	  encrypt_keys,         %% encrypt keys
	  encrypt_block_size = 8,
	  encrypt_ctx,

	  decrypt = none,       %% decrypt algorithm
	  decrypt_keys,         %% decrypt keys
	  decrypt_block_size = 8,
	  decrypt_ctx,          %% Decryption context   

	  compress = none,
	  compress_ctx,
	  decompress = none,
	  decompress_ctx,

	  c_lng=none,   %% client to server languages
	  s_lng=none,   %% server to client languages

	  user_ack    = true,   %% client
	  timeout     = infinity,

	  shared_secret,        %% K from key exchange
	  exchanged_hash,       %% H from key exchange
	  session_id,           %% same as FIRST exchanged_hash
	  
	  opts = [],
	  send_sequence = 0,
	  recv_sequence = 0,
	  keyex_key,
	  keyex_info,
	  random_length_padding = ?MAX_RND_PADDING_LEN, % From RFC 4253 section 6.
	  
	  %% User auth
	  user,
	  service,
	  userauth_quiet_mode,              %  boolean()
	  userauth_methods,                 %  list( string() )  eg ["keyboard-interactive", "password"]
	  userauth_supported_methods,       %  string() eg "keyboard-interactive,password"
          userauth_pubkeys,
	  kb_tries_left = 0,                %  integer(), num tries left for "keyboard-interactive"
	  userauth_preference,
	  available_host_keys,
	  pwdfun_user_state,
	  authenticated = false
	 }).

-record(alg,
	{
	  kex,
	  hkey,
	  send_mac,
	  recv_mac,
	  encrypt,
	  decrypt,
	  compress,
	  decompress,
	  c_lng,
	  s_lng,
          send_ext_info,
          recv_ext_info
	 }).

-record(ssh_key,
	{
	  type,
	  public,
	  private,
	  comment = ""
	 }).

-record(ssh_pty, {term = "", % e.g. "xterm"
		  width = 80,
		  height = 25,
		  pixel_width = 1024,
		  pixel_height = 768,
		  modes = <<>>}).

%% assertion macro
-define(ssh_assert(Expr, Reason),
	case Expr of
	    true -> ok;
	    _ -> exit(Reason)
	end).

-endif. % SSH_HRL defined
