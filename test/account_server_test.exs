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
