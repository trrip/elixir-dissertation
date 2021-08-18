defmodule Coordinator do
  use GenServer

  def createCoordinator(name) do
    # some how generate a new name...
    GenServer.start_link(__MODULE__, [protocol: nil, callBackHandler: nil, procs: []], name: name)
  end

  def commit(name, processName) do
    # have to save this new state to the server
    GenServer.cast(name, {:modify_status_commit, [data: processName, name: name]})
  end

  def abort(name, processName) do
    # have to save this new state to the server
    GenServer.cast(name, {:modify_status_abort, [data: processName, name: name]})
  end

  def setCallBackFunction(name, functionName) do
    # have to save this new state to the server
    GenServer.cast(name, {:set_function, functionName})
  end

  def setProtocolFunction(name, protocolName) do
    # have to save this new state to the server
    GenServer.cast(name, {:set_protocol, protocolName})
  end

  def addProcess(name, process) do
    # have to save this new state to the server
    GenServer.cast(name, {:store_proc, process})
  end

  def getTheBatch(name) do
    GenServer.call(name, :list)
  end

  def closeCoordinator(name) do
    GenServer.stop(name, :normal, :infinity)
  end

  def init(initialValue) do
    {:ok, initialValue}
  end

  def terminate(_reason, _list) do
    # IO.puts("we are closing the server_________")
    # IO.inspect(list)
  end

  def handle_cast({:store_proc, newProc}, list) do
    localValue = [
      protocol: list[:protocol],
      callBackHandler: list[:callBackHandler],
      procs: list[:procs] ++ [newProc]
    ]

    {:noreply, localValue}
  end

  def handle_cast({:set_function, newCallBackHandler}, list) do
    localValue = [
      protocol: list[:protocol],
      callBackHandler: newCallBackHandler,
      procs: list[:procs]
    ]

    {:noreply, localValue}
  end

  def handle_cast({:set_protocol, protocol}, list) do
    localValue = [
      protocol: protocol,
      callBackHandler: list[:callBackHandler],
      procs: list[:procs]
    ]

    {:noreply, localValue}
  end

  def handle_cast({:modify_status_abort, processName}, list) do
    newList =
      Enum.map(list[:procs], fn element ->
        if element[:processDetails].name == processName[:data] do
          [
            processId: element[:processId],
            processDetails: element[:processDetails],
            roleSelected: element[:roleSelected],
            status: "abort"
          ]
        else
          element
        end
      end)

    localValue = [
      protocol: list[:protocol],
      callBackHandler: list[:callBackHandler],
      procs: newList
    ]

    list[:callBackHandler].(false, list[:procs], list[:protocol])
    # In 2 seconds
    {:stop, "sample", "", []}
    {:noreply, localValue}
  end

  #   #[
  #   processId: #PID<0.159.0>,
  #   processDetails: %ConProcess{
  #     name: "clientName2",
  #     roleType: ["client"],
  #     work: #Function<2.13401323/4 in Index.entery/0>
  #   },
  #   roleSelected: "client",
  #   status: "started"
  # ]
  # modift this
  def handle_cast({:modify_status_commit, processName}, list) do
    newList =
      Enum.map(list[:procs], fn element ->
        if element[:processDetails].name == processName[:data] do
          [
            processId: element[:processId],
            processDetails: element[:processDetails],
            roleSelected: element[:roleSelected],
            status: "commit"
          ]
        else
          element
        end
      end)

    value =
      Enum.filter(newList, fn element ->
        element[:status] == "commit"
      end)

    count = Enum.count(value) == Enum.count(list[:procs])
    # should decide what to do when all the status are true.

    if count do
      # IO.puts("we have done execution ->>>>>>>>>>>>>>>>")
      list[:callBackHandler].(true, list[:procs], list[:protocol])
      {:stop, :normal, []}
    else
      localValue = [
        protocol: list[:protocol],
        callBackHandler: list[:callBackHandler],
        procs: newList
      ]

      {:noreply, localValue}
    end
  end

  def handle_call(:list, _from, list) do
    # atom   response new_state.
    {:reply, list, list}
  end
end
