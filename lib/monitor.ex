# make monitor a otp so that it can take things as input and store things
defmodule Monitor do
  require Coordinator

  defstruct id: String,
            name: Atom

  # onCompletionCallBack: nil

  defmacro __using__(_opts) do
    IO.puts("You are USING Monitor")
  end

  # def commit(monitor, task) do
  #   Coordinator.commit(monitor.name, task)
  # end

  # def abort(monitor, task) do
  #   Coordinator.abort(monitor.name, task)
  # end
end
