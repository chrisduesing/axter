defmodule Axter.ErrorHandler do
  
  defmacro handle_unknown do
    quote do
      defp handle(source, message_type, message, state, sender) do
        Util.log.debug("Recieved unhandled message: #{inspect source}, #{inspect message_type}, #{inspect message}")
        if message_type == :api do
          sender <- {:error, :unknown_message}
        end
      end
    end
  end
      
end