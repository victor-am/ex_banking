defmodule AccountServerTest do
  use ExUnit.Case
  alias ExBanking.AccountServer
  doctest AccountServer

  describe "spawn_account/1" do
    test "returns {:ok, #PID<...>}" do
      assert {:ok, pid} = AccountServer.spawn_account("Harry")
      assert is_pid(pid)
    end

    test "spawns a process with the correct name under AccountsSupervisor" do
      AccountServer.spawn_account("Ted")
      pid = Process.whereis(:TedAccount)
      assert Process.alive?(pid) == true
    end

    test "returns an error when the user already exists" do
      AccountServer.spawn_account("Marta")
      assert {:error, {:already_started, pid}} = AccountServer.spawn_account("Marta")
      assert is_pid(pid)
    end
  end

  describe "call/2" do
    test "dispatches a message to the user's AccountServer" do
      AccountServer.spawn_account("Carlos")
      assert {:ok, 0} = AccountServer.call("Carlos", {:get_balance, "USD"})
    end

    test "returns an error when the process cannot be found" do
      assert AccountServer.call("Santa Claus", {:get_balance, "USD"}) ==
               {:error, :process_not_found, :get_balance}
    end

    test "returns an error when the process mailbox is already full" do
      AccountServer.spawn_account("Lin")

      # This simulates a queue with 10 messages
      defmodule StubbedProcess do
        def info(_pid, :message_queue_len), do: {:message_queue_len, 10}
      end

      Application.put_env(:ex_banking, :process_module, StubbedProcess)

      assert AccountServer.call("Lin", {:get_balance, "USD"}) ==
               {:error, :process_mailbox_is_full, :get_balance}

      Application.delete_env(:ex_banking, :process_module)
    end
  end

  describe "handle_call/2 => :get_balance" do
    test "returns the balance of a user" do
      state = %{"USD" => 100}
      message = {:get_balance, "USD"}
      expected_response = {:reply, {:ok, 100}, %{"USD" => 100}}
      assert AccountServer.handle_call(message, {}, state) == expected_response
    end
  end

  describe "handle_call/2 => :deposit" do
    test "adds the specified amount of money into the user's account" do
      state = %{"USD" => 100}
      message = {:deposit, 100, "USD"}
      expected_response = {:reply, {:ok, 200}, %{"USD" => 200}}
      assert AccountServer.handle_call(message, {}, state) == expected_response
    end
  end

  describe "handle_call/2 => :withdraw" do
    test "removes the specified amount of money from the user's account" do
      state = %{"USD" => 100}
      message = {:withdraw, 5, "USD"}
      expected_response = {:reply, {:ok, 95}, %{"USD" => 95}}
      assert AccountServer.handle_call(message, {}, state) == expected_response
    end

    test "returns an error and keeps the balance when the user doesn't have enough money" do
      state = %{"USD" => 100}
      message = {:withdraw, 150, "USD"}
      expected_response = {:reply, {:error, :not_enough_money, :withdraw}, %{"USD" => 100}}
      assert AccountServer.handle_call(message, {}, state) == expected_response
    end
  end
end
