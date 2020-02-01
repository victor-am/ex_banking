defmodule AccountServerTest do
  use ExUnit.Case
  alias ExBanking.AccountServer
  doctest AccountServer

  describe "spawn_account/1" do
    test "it returns {:ok, #PID<...>}" do
      assert {:ok, pid} = AccountServer.spawn_account("Harry")
      assert is_pid(pid)
    end

    test "it spawns a process with the correct name under AccountsSupervisor" do
      AccountServer.spawn_account("Ted")
      pid = Process.whereis(:TedAccount)
      assert Process.alive?(pid) == true
    end

    test "it returns an error when the user already exists" do
      AccountServer.spawn_account("Marta")
      assert {:error, {:already_started, pid}} = AccountServer.spawn_account("Marta")
      assert is_pid(pid)
    end
  end

  describe "call/2" do
    test "it dispatches a message to the user's AccountServer" do
      AccountServer.spawn_account("Carlos")
      assert {:ok, 0} = AccountServer.call("Carlos", {:get_balance, "USD"})
    end

    test "it returns an error when the process cannot be found" do
      assert AccountServer.call("Santa Claus", {:get_balance, "USD"}) ==
               {:error, :process_not_found}
    end

    test "it returns an error when the process mailbox is already full" do
      AccountServer.spawn_account("Lin")

      # This simulates a queue with 10 messages
      defmodule StubbedProcess do
        def info(_pid, :message_queue_len), do: {:message_queue_len, 10}
      end

      assert AccountServer.call("Lin", {:get_balance, "USD"}, StubbedProcess) ==
               {:error, :process_mailbox_is_full}
    end
  end

  describe "handle_call/2 => :get_balance" do
    test "it returns the balance of a user" do
      state = %{"USD" => 100}
      message = {:get_balance, "USD"}
      expected_response = {:reply, {:ok, 100}, %{"USD" => 100}}
      assert AccountServer.handle_call(message, {}, state) == expected_response
    end
  end

  describe "handle_call/2 => :deposit" do
    test "it adds the specified amount of money into the users account" do
      state = %{"USD" => 100}
      message = {:deposit, 100, "USD"}
      expected_response = {:reply, {:ok, 200}, %{"USD" => 200}}
      assert AccountServer.handle_call(message, {}, state) == expected_response
    end
  end
end
