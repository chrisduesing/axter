defmodule Axter.Util do

  def hash(object) do
    bin = :erlang.term_to_binary(object)
    <<sha::size(160)>> = :crypto.sha(bin)
    hex = :lists.flatten(:io_lib.format("~.16B",[sha]))
    :erlang.list_to_binary(hex)
  end

end