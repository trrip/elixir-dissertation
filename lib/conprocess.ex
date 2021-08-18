defmodule ConProcess do
  defstruct roleType: [],
            work: nil,
            name: nil

  defmacro __using__(_opts) do
    IO.puts("You are USING Proc")
  end
end
