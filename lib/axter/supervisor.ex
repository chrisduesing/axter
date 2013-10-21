defmodule Axter.Supervisor do
  use Supervisor.Behaviour

  # start the supervisor
  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  # The callback invoked when the supervisor starts
  def init([]) do
    children = [ worker(Axter.DataStore, [], restart: :permanent) ]
    supervise children, strategy: :one_for_one
  end
end