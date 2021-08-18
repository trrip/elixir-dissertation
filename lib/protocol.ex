defmodule ConsensusProtocol do
  # server, client, <- input methods
  # commit and abort method
  # send message , inbox message
  defstruct id: String,
            protocol: []

  defmacro __using__(_opts) do
    IO.puts("You are USING Proc")
  end

  # #
  # @type t(name, server) :: %Proc{name: name, server: server}

  # @type t :: %Proc{name: String, server: function()}

  # def delete(hi) do
  #   IO.puts("this will delete")
  # end
end
