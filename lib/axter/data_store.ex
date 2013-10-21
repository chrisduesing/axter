defmodule Axter.DataStore do
  use GenServer.Behaviour


  # API functions
  ######################
  def start_link() do
    :gen_server.start_link({ :local, :data_store }, __MODULE__, [], [])
  end

  def init([]) do
    {:ok, HashDict.new(data_by_id: HashDict.new, id_by_pid: HashDict.new, pid_by_id: HashDict.new, pid_locks: HashDict.new, lock_subscribers: HashDict.new)}
  end

  def retrieve(type, id) do
    :gen_server.call :data_store, {:retrieve, type, id}
  end

  def persist(type, id, data) do
    :gen_server.call :data_store, {:persist, type, id, data}
  end

  def register(type, id, pid, data) do
    :gen_server.call :data_store, {:register, type, id, pid, data}
  end

  def lookup(type, id_or_pid) do
    :gen_server.call :data_store, {:lookup, type, id_or_pid}
  end


  # Handlers
  ################

  def handle_call({:retrieve, type, id}, _sender, state) do
    data = get_data(state, type, id)
    { :reply, data, state }
  end

  def handle_call({:persist, type, id, data}, _sender, state) do
    state = put_data(state, type, id, data) 
    { :reply, :ok, state }
  end

  def handle_call({:register, type, id, pid, data}, _sender, state) do
    state = put_id(state, type, pid, id) 
    state = put_pid(state, type, id, pid) 
    state = put_data(state, type, id, data) 
    lock_subscribers = get_lock_subscribers(state, id)
    Enum.each lock_subscribers, fn(subscriber) -> subscriber <- {:unlocked, pid} end
    state = reset_lock_subscribers(state, id)
    { :reply, :ok, state }
  end

  def handle_call({:lookup, type, pid}, _sender, state) when is_pid(pid) do
    id = get_id(state, type, pid)
    { :reply, id, state }
  end

  def handle_call({:lookup, type, id}, {sender, _tag}, state) do
    pid = get_pid(state, type, id)
    # response = {:error, :not_found}
    if :erlang.is_process_alive(pid) do
      response = {:lookup, {:ok, pid}}
    else
      if get_pid_lock(state, id) == nil do
        state = put_pid_lock(state, id, sender)
        response = {:lookup, {:error, :locking}}
      else
        state = add_lock_subscriber(state, id, sender)
        response = {:lookup, {:wait, :locked}}
      end
    end
    { :reply, response, state }
  end
  

  # Helpers
  ##############

  defp get_data(state, type, id) do
    data_dict = Dict.get(state, :data_by_id)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    Dict.get(type_dict, id)
  end

  defp put_data(state, type, id, data) do
    data_dict = Dict.get(state, :data_by_id)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    type_dict = Dict.put(type_dict, id, data)
    data_dict = Dict.put(data_dict, type, type_dict)
    Dict.put(state, :data_by_id, data_dict)
  end

  defp get_id(state, type, pid) do
    data_dict = Dict.get(state, :id_by_pid)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    Dict.get(type_dict, :erlang.pid_to_list(pid))
  end

  defp put_id(state, type, pid, id) do
    id_dict = Dict.get(state, :id_by_pid)
    type_dict = Dict.get(id_dict, type, HashDict.new)
    type_dict = Dict.put(type_dict, :erlang.pid_to_list(pid), id)
    id_dict = Dict.put(id_dict, type, type_dict)
    Dict.put(state, :id_by_pid, id_dict)
  end

  defp get_pid(state, type, id) do
    data_dict = Dict.get(state, :pid_by_id)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    pid_list = Dict.get(type_dict, id)
    :erlang.list_to_pid(pid_list)
  end

  defp put_pid(state, type, id, pid) do
    pid_dict = Dict.get(state, :pid_by_id)
    type_dict = Dict.get(pid_dict, type, HashDict.new)
    type_dict = Dict.put(type_dict, id, :erlang.pid_to_list(pid))
    pid_dict = Dict.put(pid_dict, type, type_dict)
    Dict.put(state, :pid_by_id, pid_dict)
  end

  defp get_pid_lock(state, id) do
    pid_lock_dict = Dict.get(state, :pid_locks)
    Dict.get(pid_lock_dict, id)
  end

  defp put_pid_lock(state, id, pid) do
    pid_lock_dict = Dict.get(state, :pid_locks)
    pid_lock_dict = Dict.put(pid_lock_dict, id, :erlang.pid_to_list(pid))
    Dict.put(state, :pid_locks, pid_lock_dict)
  end

  defp get_lock_subscribers(state, id) do
    lock_subscribers_dict = Dict.get(state, :lock_subscribers)
    Dict.get(lock_subscribers_dict, id, [])
  end

  defp add_lock_subscriber(state, id, lock_subscriber) do
    lock_subscribers_dict = Dict.get(state, :lock_subscribers)
    lock_subscribers = Dict.get(lock_subscribers_dict, id, [])
    lock_subscribers = [lock_subscriber | lock_subscribers]
    lock_subscribers_dict = Dict.put(lock_subscribers, id, lock_subscribers)
    Dict.put(state, :lock_subscribers, lock_subscribers_dict)
  end

  defp reset_lock_subscribers(state, id) do
    lock_subscribers_dict = Dict.get(state, :lock_subscribers)
    lock_subscribers_dict = Dict.put(lock_subscribers_dict, id, [])
    Dict.put(state, :lock_subscribers, lock_subscribers_dict)
  end

end