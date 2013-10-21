defmodule Axter do
  defmacro __using__(_opts) do
    quote do
      @behaviour Axter.Actor

      # Public API 
      #####################

      @doc """
      Create an instance (running process) passing in any optional state as a param list 
      
      e.g. Something.new([name: "bob", age: 30])
      where 'Something' is the name of the module that uses Axter
      """
      def new, do: start(HashDict.new)
      def new(params) when is_list(params), do: start(HashDict.new(params))

      # look up data by id
      def find(id) do
        result = Axter.DataStore.lookup(__MODULE__, id)
        case result do
          {:ok, pid} -> 
            pid
          {:wait, :locked} ->
            receive do
              {:unlocked, pid} -> pid
            end
          other ->
            lookup_data_and_start(id)
        end          
      end

      @doc "get the id"
      def id(pid), do: sync_call(pid, :id)

      @doc "save to the database"
      def save(pid), do: sync_call(pid, :save)

      @doc "kill the process, does not delete the underlying data."
      def stop(pid) do
        :erlang.exit(pid, :kill) 
      end

      @doc "ask to be notified of events, of a specified type, that happen to this actor"
      def subscribe(pid, event_type, subscriber), do: sync_call(pid, :add_subscriber, {event_type, subscriber})
      @doc "ask to stop being notified of events, of a specified type, that happen to this actor"
      def unsubscribe(pid, event_type, subscriber), do: sync_call(pid, :remove_subscriber, {event_type, subscriber})

      @doc "tell this actor about a specific event, which they have not subscribed to. Keep in mind, they may not have implemented a handler."
      def notify(pid, event_type, message), do: pid <- {:event, event_type, message, self()}

      # Private
      #####################

      # create a running process
      defp start(state) do
        state = actor_init(state)
        pid = spawn(__MODULE__, :loop, [state])
        id = Dict.get(state, :id)
        Axter.DataStore.register(__MODULE__, id, pid, state)
        pid
      end

      defp actor_init(state) do
        if Dict.get(state, :created_at) == nil do
          state = Dict.put(state, :created_at, :erlang.now())
        end
        if Dict.get(state, :id) == nil do
          state = Dict.put(state, :id, Axter.Util.hash(state))
        end
        if Dict.get(state, :subscribers) == nil do
          state = Dict.put(state, :subscribers, HashDict.new)
        end
        init(state) #callback
      end

      # called by start, can't make private or spawn won't work
      def loop(state) do
        receive do
          {source, message_type, message, sender} when is_pid(sender) ->
            state = handle(source, message_type, message, state, sender)
          error ->
            handle(:unknown, :error, error, state, nil)
        end
        loop(state)
      end

      # Handlers
      ###################

      # save
      defp handle(:api, :save, nil, state, sender) do
        case Axter.DataStore.persist(__MODULE__, Dict.get(state, :id), HashDict.to_list(state)) do
          :ok ->
            sender <- {:save, true}
          _ ->
            sender <- {:save, false}
        end
        state
      end

      # id
      defp handle(:api, :id, nil, state, sender) do
        sender <- {:id, Dict.get(state, :id)}
        state
      end

      defp handle(:api, :add_subscriber, {event_type, subscriber}, state, sender) do
        subscribers = Dict.get(state, :subscribers)
        event_subscribers = Dict.get(subscribers, event_type, [])
        event_subscribers = [subscriber | event_subscribers]
        subscribers = Dict.put(subscribers, event_type, event_subscribers)
        state = Dict.put(state, :subscribers, subscribers)
        sender <- {:add_subscriber, :ok}
        state
      end

      defp handle(:api, :remove_subscriber, {event_type, subscriber}, state, sender) do
        subscribers = Dict.get(state, :subscribers)
        event_subscribers = Dict.get(subscribers, event_type, [])
        event_subscribers = List.delete(event_subscribers, subscriber)
        subscribers = Dict.put(subscribers, event_type, event_subscribers)
        state = Dict.put(state, :subscribers, subscribers)
        sender <- {:remove_subscriber, :ok}
        state
      end

      # Private Utilities
      #########################

      defp lookup_data_and_start(id) do
        data = Axter.DataStore.retrieve(__MODULE__, id)
        cond do
          data == nil ->
            {:error, :not_found}
          true ->
            state = HashDict.new(data)
            start(state)
        end
      end
      

      # brodcast to my listeners
      defp broadcast(event_type, message, state) do
        subscribers = Dict.get(state, :subscribers)
        event_subscribers = Dict.get(subscribers, event_type, [])
        Enum.each(event_subscribers, fn(subscriber) -> subscriber <- {:event, event_type, message, self()} end)
      end
      
      # am I alive?
      def ensure(pid) when is_pid(pid) do
        cond do
          :erlang.is_process_alive(pid) ->
            pid
          true ->
            id = Axter.DataStore.lookup(__MODULE__, pid)
            find(id)
        end
      end

      # helper for api functions
      # makes synchronous call to appropriate handler
      def sync_call(pid, message_type) do
        sync_call(pid, message_type, nil) 
      end

      def sync_call(pid, message_type, message) do
        async_call(pid, message_type, message)
        sync_return(message_type)
      end

      # makes asynchronous call to appropriate handler
      def async_call(pid, message_type) do
        async_call(pid, message_type, nil) 
      end

      def async_call(pid, message_type, message) do
        pid = ensure(pid)
        pid <- {:api, message_type, message, self()}
      end

      # waits for response from handler and returns it to caller
      defp sync_return(msg_type) do 
        receive do
          {^msg_type, message} ->
            message
        after 1000 ->
                :error
        end
      end

      # import and include dependancies
      require Axter.Attribute
      import Axter.Attribute

      require Axter.ErrorHandler
      import Axter.ErrorHandler

    end
  end
end
