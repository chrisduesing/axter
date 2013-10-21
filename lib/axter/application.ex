defmodule Axter.Application do

  def start(_type, _) do 
    Axter.Supervisor.start_link
  end

end