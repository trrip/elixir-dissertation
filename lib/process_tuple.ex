defmodule ProcessTuple do
  defstruct name: nil,
            role: nil,
            address: nil,
            status: nil

  defmacro __using__(_opts) do
    IO.puts("You are USING Proc")
  end
end
