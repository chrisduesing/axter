defmodule Axter.Attribute do

  defmacro attribute(attr, type) do

    quote1 = cond do
      type == :atom ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_atom(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :boolean ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_boolean(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :float ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_float(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :integer ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_integer(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :list ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_list(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :number ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_number(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :pid ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_pid(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :string ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_binary(value), do: sync_call(pid, unquote(attr), value)
        end
      type == :tuple ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid) and is_tuple(value), do: sync_call(pid, unquote(attr), value)
        end
      true ->
        quote do
          def unquote(attr)(pid, value) when is_pid(pid), do: sync_call(pid, unquote(attr), value)
        end
    end

    quote2 = quote do 
      def unquote(attr)(pid) when is_pid(pid), do: sync_call(pid, unquote(attr))
      
      defp handle(:api, unquote(attr), nil, state, sender) do 
        sender <- {unquote(attr), Dict.get(state, unquote(attr))}
        state
      end
      
      defp handle(:api, unquote(attr), value, state, sender) do
        sender <- {unquote(attr), :ok}
        Dict.put(state, unquote(attr), value)
      end                  
    end

    {:__block__,[], quotelist} = quote2
    quotelist2 = [quote1 | quotelist]
    {:__block__,[], quotelist2}
  end
  
end
