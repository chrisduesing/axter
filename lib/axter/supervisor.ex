defmodule Axter.Supervisor do
  use Supervisor.Behaviour

  # start the supervisor
  def start_link do
    IO.puts "Axter.Supervisor.start_link"
    :supervisor.start_link(__MODULE__, [])
  end

  # The callback invoked when the supervisor starts
  def init([]) do
    IO.puts "Axter.Supervisor.init"
    children = [ worker(Axter.DataStore, [], restart: :permanent) ]
    supervise children, strategy: :one_for_one
  end
end