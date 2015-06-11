-module(wok_topics_sup).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-define(CHILD(ID, I, Type, Args), {ID, {I, start_link, Args}, permanent, 2000, Type, [I]}).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  Childs = case application:get_env(wok, topics) of
             {ok, Topics} ->
               build_childs(Topics);
             undefined ->
               lager:info("No topic declared in config!"),
               []
           end,
  {ok, {
     {one_for_one, 5, 10},
     Childs
    }
  }.

build_childs(Topics) ->
  build_childs(Topics, []).

build_childs([], Childs) ->
  Childs;
build_childs([{Name, Options}|Rest], Childs) ->
  build_childs(Rest,
               [?CHILD(eutils:to_atom(Name), wok_topic, worker, [Name, Options])|
                Childs]).

