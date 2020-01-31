defmodule ExBanking.AccountServer do
  @moduledoc """
  The AccountServer module is a GenServer that is responsible for one user
  account at a time (multiple of them are spawned under the AccountsSupervisor).

  It handles most of the concurrency-dependent code and is in a considerably
  lower-level than the Account module for example.
  """
  use GenServer

  @initial_account_state %{"USD" => 0}

  def start_link(process_name) do
    GenServer.start_link(__MODULE__, @initial_account_state, name: process_name)
  end

  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @doc """
  Spawns a new AccountServer GenServer under the AccountsSupervisor.

  Returns `{:ok, #PID<...>}`

  ## Examples

      iex> {:ok, pid} = ExBanking.AccountServer.spawn_account("Sophie")
      ...> is_pid(pid)
      true

      iex> ExBanking.AccountServer.spawn_account("Mary")
      ...> {:error, {:already_started, pid}} = ExBanking.AccountServer.spawn_account("Mary")
      ...> is_pid(pid)
      true

  """
  def spawn_account(user) do
    child_spec = {__MODULE__, process_name(user)}
    supervisor = ExBanking.AccountsSupervisor

    DynamicSupervisor.start_child(supervisor, child_spec)
  end

  defp process_name(user) do
    String.to_atom(user <> "Account")
  end
end
