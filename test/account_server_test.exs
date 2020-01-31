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
end
