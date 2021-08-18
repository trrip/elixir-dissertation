defmodule Concurrent do
  use GenServer
  require ConsensusProtocol
  require Monitor
  require DataCollection
  require ConProcess

  # client side code / communication interface
  def open() do
    # the 2 list of array is [procList] [protocol]
    GenServer.start_link(__MODULE__, %DataCollection{}, name: __MODULE__)
  end

  # @spec setProtocol(ConsensusProtocol)
  def setProtocol(protocol) do
    GenServer.cast(__MODULE__, {:store_protocol, protocol})
  end

  def setProtocolList(protocolList) do
    GenServer.cast(__MODULE__, {:store_protocol_list, protocolList})
  end

  def setCompletionHandler(callBackFunction) do
    GenServer.cast(__MODULE__, {:set_callback_function, callBackFunction})
  end

  # register a process with process as input.
  def registerProcess(localProcess) do
    GenServer.cast(__MODULE__, {:store_proc, localProcess})
  end

  def close() do
    GenServer.stop(__MODULE__, :normal, :infinity)
  end

  def showQueue() do
    GenServer.call(__MODULE__, :list)
  end

  # server side code / business logic

  def init(initialState) do
    {:ok, initialState}
  end

  def terminate(_reason, _list) do
    # IO.puts("we are closing the server")
    # IO.inspect(list)
  end

  def handle_cast({:store_proc, newProc}, list) do
    newCollection = DataCollection.addProcess(list, newProc)

    processGrouped = DataCollection.findMatchingProcessToProtocol(newCollection)

    DataCollection.startExecutionOfProcesses(processGrouped, list.callBackHandler)
    newCollection = DataCollection.removeProcessesFromGrouped(newCollection, processGrouped)
    {:noreply, newCollection}
  end

  def handle_cast({:set_callback_function, newFunction}, list) do
    newCollection = DataCollection.addCallBackHandler(list, newFunction)
    {:noreply, newCollection}
  end

  def handle_cast({:store_protocol_list, newProtocolList}, list) do
    newCollection = DataCollection.addListOfProtocol(list, newProtocolList)
    {:noreply, newCollection}
  end

  def handle_cast({:store_protocol, newProtocol}, list) do
    newCollection = DataCollection.addProtocol(list, newProtocol)
    {:noreply, newCollection}
  end

  # def handle_cast({:withdraw, amount}, balance) do
  #   {:noreply, balance - amount}
  # end

  def handle_call(:list, _from, queue) do
    # atom   response new_state.
    # IO.puts("we are inside here and checking")
    # IO.inspect(queue)
    {:reply, queue, queue}
  end
end
