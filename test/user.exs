defmodule User do
  use Axter

  def init(state), do: state

  handle_unknown

end

defmodule UserWithName do
  use Axter

  attribute :name, :string

  def new(name) when is_binary(name), do: new([name: name])
  def init(state), do: state

  handle_unknown

end