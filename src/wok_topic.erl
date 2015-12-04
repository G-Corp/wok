% @hidden
-module(wok_topic).
-compile([{parse_transform, lager_transform}]).
-behaviour(gen_server).
-include("../include/wok.hrl").
-define(SERVER, ?MODULE).
-record(topic, {
          fetch_frequency,
          max_bytes,
          max_messages,
          consumer_group,
          name
         }).

-export([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

start_link(Name, Options) ->
  lager:info("Start topic ~s", [Name]),
  case doteki:get_env([wok, messages, consumer_group]) of
    undefined ->
      lager:error("Missing consumer group in configuration"),
      {error, missing_consumer_group};
    ConsumerGroup ->
      gen_server:start_link({local,
                             bucs:to_atom(Name)},
                            ?MODULE,
                            [{consumer_group, ConsumerGroup}, {name, Name}|Options],
                            [])
  end.

%% ------------------------------------------------------------------

init(Args) ->
  Frequency = buclists:keyfind(fetch_frequency, 1, Args, ?DEFAULT_FETCH_FREQUENCY),
  Topic = #topic{
             fetch_frequency = Frequency,
             max_bytes = buclists:keyfind(max_bytes, 1, Args, ?DEFAULT_MESSAGE_MAX_BYTES),
             max_messages = buclists:keyfind(max_messages, 1, Args, ?DEFAULT_MAX_MESSAGES),
             consumer_group = buclists:keyfind(consumer_group, 1, Args),
             name = buclists:keyfind(name, 1, Args)
            },
  erlang:send_after(Frequency, self(), fetch),
  {ok, Topic}.

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(fetch, #topic{fetch_frequency = Frequency,
                          name = Topic,
                          consumer_group = ConsumerGroup,
                          max_bytes = MaxBytes,
                          max_messages = MaxMessages} = State) ->
  LocalQueue = bucs:to_atom(
                 doteki:get_env([wok, messages, local_queue_name],
                                 ?DEFAULT_LOCAL_QUEUE)),
  case pipette:ready(LocalQueue) of
    true ->
      lager:debug("Fetch topic ~s", [Topic]),
      _ = case kafe:offsets(Topic, ConsumerGroup, MaxMessages) of
            Offsets when is_list(Offsets), Offsets =/= [] ->
              lager:debug("Topic ~s will fetch ~p", [Topic, Offsets]),
              lists:foreach(
                fun({Partition, Offset}) ->
                    lager:debug("Fetch message #~p on ~p / ~p", [Offset, Topic, Partition]),
                    case kafe:fetch(-1, Topic, #{partition => Partition, offset => Offset, max_bytes => MaxBytes}) of
                      {ok, [#{partitions := Partitions}]} ->
                        lists:foreach(fun wok_dispatcher:handle/1,
                                      [{Key, Value} ||
                                       #{message := #{key := Key, value := Value}} <- Partitions, Value =/= <<>>]);
                      _ ->
                        lager:error("Error fetching message ~p@~p#~p", [Topic, Partition, Offset])
                    end
                end, Offsets);
            _ ->
              lager:debug("No new message on ~p for ~p", [Topic, ConsumerGroup])
          end,
      erlang:send_after(Frequency, self(), fetch);
    false ->
      erlang:send_after(1000, self(), fetch)
  end,
  {noreply, State};
handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

