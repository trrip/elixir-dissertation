defmodule ThreeWay do
  require Concurrent

  def workFunction(protcolId, selfRole, coordinator, proc) do
    if protcolId == "3WayRand" do
      receive do
        {:start, _value} ->
          if(selfRole == "client") do
            batchValue = Coordinator.getTheBatch(coordinator)
            IO.inspect(batchValue)

            serverId =
              Enum.filter(batchValue[:procs], fn iter ->
                # [head | _] = iter
                tempValue = iter[:roleSelected]

                if tempValue == "server" do
                  true
                else
                  false
                end
              end)

            [head | _] = serverId
            send(head[:processId], {:value, [senderId: self(), value: 10]})

            workFunction(protcolId, selfRole, coordinator, proc)
          else
            workFunction(protcolId, selfRole, coordinator, proc)
          end

        {:return_value, value} ->
          if value < 10 do
            Coordinator.abort(coordinator, proc.name)
          else
            Coordinator.commit(coordinator, proc.name)
          end

          workFunction(protcolId, selfRole, coordinator, proc)

        {:value, someValue} ->
          # IO.inspect(someValue)
          if selfRole == "server" do
            returnValue = someValue[:value] + Enum.random([1, -1, 1, -1, 1])

            send(someValue[:senderId], {:return_value, returnValue})
            Coordinator.commit(coordinator, proc.name)

            workFunction(
              protcolId,
              selfRole,
              coordinator,
              proc
            )
          else
            workFunction(
              protcolId,
              selfRole,
              coordinator,
              proc
            )
          end

        {:abort, _} ->
          IO.puts("we are aborting")
      end
    end
  end

  def workFunctionServer(protcolId, selfRole, coordinator, monitor) do
    if protcolId === "2WayRand" do
      # serverId = findServer(listOfTupleOfParticipants)
      # send(serverId, {:value, client1Value})
      # IO.puts(selfRole)

      receive do
        {:start, _value} ->
          # IO.inspect(value)
          workFunctionServer(protcolId, selfRole, coordinator, monitor)

        {:return_value, value} ->
          if value < 10 do
            IO.puts("we are done executing")
            # monitor.commit()
          else
            IO.puts("we are done executing")
            # monitor.abort()
          end

          workFunctionServer(protcolId, selfRole, coordinator, monitor)

        {:value, someValue} ->
          # IO.puts("we recieved value from the client")
          # IO.inspect(someValue)
          send(someValue[:senderId], {:return_value, someValue[:value] + 1})
          Coordinator.commit(coordinator, monitor.name)

          workFunctionServer(
            protcolId,
            selfRole,
            coordinator,
            monitor
          )

        {:abort, _} ->
          IO.puts("we are aborting")
      end
    end
  end

  def threeWay do
    Concurrent.open()

    protocol2 = %ConsensusProtocol{id: "3WayRand", protocol: ["server", "client", "client"]}

    Concurrent.setProtocol(protocol2)

    Concurrent.setCompletionHandler(fn isSuccess, _processes, _protocol ->
      if isSuccess do
        IO.puts("______________success_____________")
        # IO.inspect(processes)
        # IO.inspect(protocol)
      else
        IO.puts("______________failed_____________")
        # IO.inspect(processes)
        # IO.inspect(protocol)
      end

      IO.puts("End of one consensus....")
    end)

    # client1Value = 10

    process1 = %ConProcess{
      name: "clientName1",
      roleType: ["client"],
      work: fn protocol, role, coordinator, monitor ->
        spawn(ThreeWay, :workFunction, [protocol, role, coordinator, monitor])
      end
    }

    process2 = %ConProcess{
      name: "serverName1",
      roleType: ["server", "client"],
      work: fn protocol, role, coordinator, monitor ->
        spawn(ThreeWay, :workFunction, [protocol, role, coordinator, monitor])
      end
    }

    process3 = %ConProcess{
      name: "clientName2",
      roleType: ["server", "client"],
      work: fn protocol, role, coordinator, monitor ->
        spawn(ThreeWay, :workFunction, [protocol, role, coordinator, monitor])
      end
    }

    Concurrent.registerProcess(process1)
    Concurrent.registerProcess(process2)
    # Concurrent.showQueue()

    Concurrent.registerProcess(process3)
    # Concurrent.showQueue()
  end
end
