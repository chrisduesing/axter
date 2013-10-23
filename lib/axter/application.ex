defmodule Axter.Application do

  def start(_type, _) do 
    IO.puts "Axter.Application.start"
    Axter.Supervisor.start_link
  end

end