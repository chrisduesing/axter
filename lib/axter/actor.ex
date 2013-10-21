defmodule Axter.Actor do
  use Behaviour

  @doc "Initialize the actor with any desired state."
  defcallback init(state :: Dict.t) :: Dict.t

end