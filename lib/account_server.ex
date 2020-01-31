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
  Callback from GenServer implementing the get_balance logic.
  More information on the AccountServer.call function documentation.
  """
  @impl GenServer
  def handle_call({:get_balance, currency}, _from, state) do
    balance = state[currency] || 0
    {:reply, {:ok, balance}, state}
  end

  @doc """
  Callback from GenServer implementing the deposit logic.
  More information on the AccountServer.call function documentation.
  """
  @impl GenServer
  def handle_call({:deposit, amount, currency}, _from, state) do
    balance = state[currency] || 0
    new_state = %{currency => balance + amount}
    {:reply, {:ok, new_state[currency]}, new_state}
  end

  @doc """
  Spawns a new AccountServer GenServer under the AccountsSupervisor.

  Returns `{:ok, #PID<...>}`

  ## Examples

      iex> {:ok, pid} = AccountServer.spawn_account("Sophie")
      ...> is_pid(pid)
      true

      iex> AccountServer.spawn_account("Mary")
      ...> {:error, {:already_started, pid}} = ExBanking.AccountServer.spawn_account("Mary")
      ...> is_pid(pid)
      true

  """
  def spawn_account(user) do
    child_spec = {__MODULE__, process_name(user)}
    supervisor = ExBanking.AccountsSupervisor

    DynamicSupervisor.start_child(supervisor, child_spec)
  end

  @doc """
  Calls the AccountServer process of the given user and returns whatever the the
  process returns from the given message.

  ## Examples

      iex> AccountServer.spawn_account("Lara")
      ...> AccountServer.call("Lara", {:get_balance, "USD"})
      {:ok, 0}

      iex> AccountServer.spawn_account("Francis")
      ...> AccountServer.call("Francis", {:deposit, 100, "USD"})
      {:ok, 100}

  """
  def call(user, action_options) do
    pid = process_id(user)

    if pid do
      GenServer.call(pid, action_options)
    else
      {:error, :process_not_found}
    end
  end

  defp process_id(user) do
    process_name(user)
    |> Process.whereis()
  end

  defp process_name(user) do
    String.to_atom(user <> "Account")
  end
end
