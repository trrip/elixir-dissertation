defmodule DataCollection do
  require Coordinator
  require Monitor

  defstruct protocolList: [],
            processList: [],
            inExecutionProcess: [],
            callBackHandler: nil

  defmacro __using__(_opts) do
    IO.puts("You are USING Data collection")
  end

  def addProcessList(collection, processList) do
    %DataCollection{
      protocolList: collection.protocolList,
      processList: collection.processList ++ processList,
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: collection.callBackHandler
    }
  end

  def addCallBackHandler(collection, callBack) do
    %DataCollection{
      protocolList: collection.protocolList,
      processList: collection.processList,
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: callBack
    }
  end

  def removeProcess(collection, process) do
    %DataCollection{
      protocolList: collection.protocolList,
      processList: collection.processList -- [process],
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: collection.callBackHandler
    }
  end

  defp getAllProcessOnlyFromGroup(group) do
    flatten(Enum.map(group, fn element -> element[:processes] end))
  end

  def removeProcessesFromGrouped(collection, group) do
    %DataCollection{
      protocolList: collection.protocolList,
      processList: collection.processList -- getAllProcessOnlyFromGroup(group),
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: collection.callBackHandler
    }
  end

  def addProcess(collection, process) do
    %DataCollection{
      protocolList: collection.protocolList,
      processList: collection.processList ++ [process],
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: collection.callBackHandler
    }
  end

  def addProtocol(collection, protocol) do
    %DataCollection{
      protocolList:
        Enum.uniq_by(collection.protocolList ++ [protocol], fn element -> element.id end),
      processList: collection.processList,
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: collection.callBackHandler
    }
  end

  def addListOfProtocol(collection, protocolList) do
    %DataCollection{
      protocolList: collection.protocolList ++ protocolList,
      processList: collection.processList,
      inExecutionProcess: collection.inExecutionProcess,
      callBackHandler: collection.callBackHandler
    }
  end

  def getRandomString(length) do
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" |> String.split("")

    Enum.reduce(1..length, [], fn _i, acc ->
      [Enum.random(chars) | acc]
    end)
    |> Enum.join("")
  end

  def startProcessWithProtocol(processes, protocol, coordinatorName, monitor, rolesAvailable) do
    # IO.inspect(processes)
    # IO.puts("******************")
    [firstPro | tail] = processes
    # IO.puts("this process ")
    # IO.inspect(firstPro)
    #
    roleSelected = Enum.find(firstPro.roleType, fn role -> role in rolesAvailable end)

    roleTail = rolesAvailable -- [roleSelected]

    processId = firstPro.work.(protocol.id, roleSelected, coordinatorName, firstPro)

    Coordinator.addProcess(coordinatorName,
      processId: processId,
      processDetails: firstPro,
      roleSelected: roleSelected,
      status: "started"
    )

    if roleTail == [] do
      [processId]
    else
      [processId] ++ startProcessWithProtocol(tail, protocol, coordinatorName, monitor, roleTail)
    end
  end

  def startExecutionOfProcesses(groupedProcesses, callBackHandler) do
    # create a new coordinator a monitor and spawn all the process and start execution.
    # reduce and get the new limited string
    # IO.puts("we are about to execute")
    # IO.inspect(groupedProcesses)

    Enum.each(groupedProcesses, fn element ->
      newCoordinatorName = String.to_atom(getRandomString(9))
      # IO.puts(newCoordinatorName)

      Coordinator.createCoordinator(newCoordinatorName)
      Coordinator.setCallBackFunction(newCoordinatorName, callBackHandler)

      Coordinator.setProtocolFunction(newCoordinatorName, element[:protocol])

      monitor = %Monitor{id: to_string(newCoordinatorName), name: newCoordinatorName}

      protocolUsed = element[:protocol]

      # IO.inspect(protocolUsed)
      sortedList =
        Enum.sort(element[:processes], fn element1, element2 ->
          Enum.count(element1.roleType) > Enum.count(element2.roleType)
        end)

      processIds =
        startProcessWithProtocol(
          sortedList,
          protocolUsed,
          newCoordinatorName,
          monitor,
          protocolUsed.protocol
        )

      Enum.each(processIds, fn proc ->
        send(proc, {:start, 1})
      end)
    end)
  end

  def flatten([head | tail]), do: flatten(head) ++ flatten(tail)
  def flatten([]), do: []
  def flatten(element), do: [element]

  def makeGroup(_, []) do
    []
  end

  def makeGroup([], _) do
    []
  end

  def makeGroup(list, protocol) do
    [head | tail] = protocol
    foundProc = Enum.find(list, [], fn element -> head in element.roleType end)
    [foundProc] ++ makeGroup(List.delete(list, foundProc), tail)
  end

  # def checkCompatiblity([], _) do
  #   false
  # end

  # def checkCompatiblity(_, []) do
  #   false
  # end

  def checkCompatiblity([], []) do
    true
  end

  def checkCompatiblity(processes, protocol) do
    if Enum.count(processes) == Enum.count(protocol) do
      [head | tail] = processes
      result = Enum.find(head.roleType, fn ele -> ele in protocol end)
      # IO.inspect(result)

      if result == nil do
        false
      else
        checkCompatiblity(tail, protocol -- [result])
      end
    else
      false
    end
  end

  def group(_, []) do
    []
  end

  def group([], _) do
    []
  end

  def group(list, protocolList) do
    [head | tail] = protocolList
    finalGroup = []

    if checkCompatiblity(list, head.protocol) do
      localGroup = makeGroup(list, head.protocol)
      localNamesOnly = Enum.map(localGroup, fn element -> element.name end)
      finalGroup = finalGroup ++ [[processes: localGroup, protocol: head]]

      finalGroup ++
        group(Enum.filter(list, fn element -> element.name not in localNamesOnly end), [head])
    else
      group(list, tail)
    end
  end

  def findMatchingProcessToProtocol(collection) do
    group(collection.processList, collection.protocolList)
  end
end
