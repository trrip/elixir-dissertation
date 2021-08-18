defmodule Horizon do
  require Concurrent

  def nodeOne(log, protcolId, selfRole, coordinator, proc) do

    if protcolId == "4WayRand" do
      if selfRole == "client" do
        receive do
          {:start, _value} ->
            batchValue = Coordinator.getTheBatch(coordinator)

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

            # send the data to server.
            [head | _] = serverId

            send(head[:processId], {:value, [senderId: self(), value: log]})

            nodeOne(log, protcolId, selfRole, coordinator, proc)

          {:commit, data} ->
            finalLog = data[:log]
            IO.puts(finalLog)
            Coordinator.commit(coordinator, proc.name)

          # nodeFour(protcolId, selfRole, coordinator, proc)
          {:abort, _} ->
            Coordinator.abort(coordinator, proc.name)

            IO.puts("we are aborting")
          after
            5000 ->
              Coordinator.abort(coordinator, proc.name)
          end
        end
      end
    end
  end

  def nodeTwo(log, protcolId, selfRole, coordinator, proc) do

    if protcolId == "4WayRand" do
      if selfRole == "client" do
        receive do
          {:start, _value} ->
            batchValue = Coordinator.getTheBatch(coordinator)

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

            # send the data to server.
            [head | _] = serverId

            send(head[:processId], {:value, [senderId: self(), value: log]})

            nodeTwo(log, protcolId, selfRole, coordinator, proc)

          {:commit, data} ->
            finalLog = data[:log]
            IO.puts(finalLog)
            Coordinator.commit(coordinator, proc.name)

          # nodeFour(protcolId, selfRole, coordinator, proc)
          {:abort, _} ->
            Coordinator.abort(coordinator, proc.name)

            IO.puts("we are aborting")
          after
            5000 ->
              Coordinator.abort(coordinator, proc.name)
          end
        end
      end
    end
  end

  def nodeThree(log, protcolId, selfRole, coordinator, proc) do
    if protcolId == "4WayRand" do
      if selfRole == "client" do
        receive do
          {:start, _value} ->
            batchValue = Coordinator.getTheBatch(coordinator)

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

            # send the data to server.
            [head | _] = serverId

            send(head[:processId], {:value, [senderId: self(), value: log]})

            nodeThree(log, protcolId, selfRole, coordinator, proc)

          {:commit, data} ->
            finalLog = data[:log]
            IO.puts(finalLog)
            Coordinator.commit(coordinator, proc.name)

          # nodeFour(protcolId, selfRole, coordinator, proc)
          {:abort, _} ->
            IO.puts("we are aborting")
            Coordinator.abort(coordinator, proc.name)
          after
            5000 ->
              Coordinator.abort(coordinator, proc.name)
          end
        end
      end
    end
  end

  def nodeFour(log, protcolId, selfRole, coordinator, proc) do
    if protcolId == "4WayRand" do
      if selfRole == "server" do
        receive do
          {:start, _value} ->
            nodeFour(log, protcolId, selfRole, coordinator, proc)

          {:value, data} ->
            localMerge = log ++ data[:value]
            # IO.inspect(localMerge)

            mergedValue =
              Enum.sort(localMerge, fn ele1, ele2 ->
                chunks1 = String.splitter(ele1, "__")
                chunks2 = String.splitter(ele2, "__")

                if Enum.at(chunks1, 2) > Enum.at(chunks2, 2) do
                  true
                else
                  false
                end
              end)

            if(length(mergedValue) == 24) do
              batchValue = Coordinator.getTheBatch(coordinator)

              clientIds =
                Enum.filter(batchValue[:procs], fn iter ->
                  # [head | _] = iter
                  tempValue = iter[:roleSelected]

                  if tempValue != "server" do
                    true
                  else
                    false
                  end
                end)

              Enum.map(clientIds, fn ele ->
                send(ele[:processId], {:commit, [log: mergedValue]})
              end)

              Coordinator.commit(coordinator, proc.name)
            else
              nodeFour(mergedValue, protcolId, selfRole, coordinator, proc)
            end
        end
      else
        if selfRole == "client" do
          receive do
            {:start, _value} ->
              batchValue = Coordinator.getTheBatch(coordinator)

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

              # send the data to server.
              [head | _] = serverId

              send(head[:processId], {:value, [senderId: self(), value: log]})

              nodeFour(log, protcolId, selfRole, coordinator, proc)

            {:commit, data} ->
              finalLog = data[:log]
              IO.inspect(finalLog)
              Coordinator.commit(coordinator, proc.name)

            # nodeFour(protcolId, selfRole, coordinator, proc)
            {:abort, _} ->
              Coordinator.abort(coordinator, proc.name)

              IO.puts("we are aborting")
          after
            5000 ->
              Coordinator.abort(coordinator, proc.name)
          end
        end
      end
    end
  end

  def runDemo do
    Concurrent.open()

    protocol2 = %ConsensusProtocol{
      id: "4WayRand",
      protocol: ["server", "client", "client", "client"]
    }

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
    log4 = [
      "NODE__4__1__log__data1",
      "NODE__4__2__log__data2",
      "NODE__4__3__log__data3",
      "NODE__4__4__log__data4",
      "NODE__4__5__log__data5",
      "NODE__4__6__log__data6"
    ]

    log1 = [
      "NODE__1__1__log__data1",
      "NODE__1__2__log__data2",
      "NODE__1__3__log__data3",
      "NODE__1__4__log__data4",
      "NODE__1__5__log__data5",
      "NODE__1__6__log__data6"
    ]

    log2 = [
      "NODE__2__1__log__data1",
      "NODE__2__2__log__data2",
      "NODE__2__3__log__data3",
      "NODE__2__4__log__data4",
      "NODE__2__5__log__data5",
      "NODE__2__6__log__data6"
    ]

    log3 = [
      "NODE__3__1__log__data1",
      "NODE__3__2__log__data2",
      "NODE__3__3__log__data3",
      "NODE__3__4__log__data4",
      "NODE__3__5__log__data5",
      "NODE__3__6__log__data6"
    ]

    process1 = %ConProcess{
      name: "NodeOne",
      roleType: ["client"],
      work: fn protocol, role, coordinator, proc ->
        spawn(Horizon, :nodeOne, [log1, protocol, role, coordinator, proc])
      end
    }

    process2 = %ConProcess{
      name: "NodeTwo",
      roleType: ["client"],
      work: fn protocol, role, coordinator, proc ->
        spawn(Horizon, :nodeTwo, [log2, protocol, role, coordinator, proc])
      end
    }

    process3 = %ConProcess{
      name: "Node3",
      roleType: ["client"],
      work: fn protocol, role, coordinator, proc ->
        spawn(Horizon, :nodeThree, [log3, protocol, role, coordinator, proc])
      end
    }

    process4 = %ConProcess{
      name: "Node4",
      roleType: ["server", "client"],
      work: fn protocol, role, coordinator, proc ->
        spawn(Horizon, :nodeFour, [log4, protocol, role, coordinator, proc])
      end
    }

    Concurrent.registerProcess(process1)
    Concurrent.registerProcess(process2)
    Concurrent.registerProcess(process3)
    Concurrent.registerProcess(process4)
    Concurrent.showQueue()
    Concurrent.showQueue()
    Concurrent.showQueue()
    Concurrent.showQueue()
    Concurrent.showQueue()

    Concurrent.showQueue()
  end
end
