defmodule Relationship do
  
  defmacro relationship(actor_type, one_or_many) do
    
    quote1 = if one_or_many == :one do
      quote do
        def unquote(actor_type)(pid, value) when is_pid(pid) and is_pid(value), do: sync_call(pid, unquote(actor_type), value)
      end
    else 
      quote do
        def unquote(actor_type)(pid, value) when is_pid(pid) and is_list(value), do: sync_call(pid, unquote(actor_type), value)
      end
    end
    
    quote2 = quote do 
      def unquote(actor_type)(pid) when is_pid(pid), do: sync_call(pid, unquote(actor_type))
    
      defp handle(:api, unquote(actor_type), nil, state, sender) do 
        sender <- {unquote(actor_type), Dict.get(state, unquote(actor_type))}
        state
      end
    
      defp handle(:api, unquote(actor_type), value, state, sender) do
        sender <- {unquote(actor_type), :ok}
        Dict.put(state, unquote(actor_type), value)
      end
    end

    {:__block__,[], quotelist} = quote2
    quotelist2 = [quote1 | quotelist]
    {:__block__,[], quotelist2}

  end
  
end
  
