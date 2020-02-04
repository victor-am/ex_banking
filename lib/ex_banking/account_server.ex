defmodule ExBanking.AccountServer do
  @moduledoc """
  The AccountServer module is a GenServer that is responsible for one user
  account at a time (multiple of them are spawned under the AccountsSupervisor).

  It handles most of the concurrency-dependent code and is in a considerably
  lower-level than the Account module for example.
  """
  use GenServer

  @process_mailbox_limit 10
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
  Examples on the AccountServer.call function documentation.
  """
  @impl GenServer
  def handle_call({:get_balance, currency}, _from, state) do
    balance = state[currency] || 0
    {:reply, {:ok, balance}, state}
  end

  @doc """
  Callback from GenServer implementing the deposit logic.
  Examples on the AccountServer.call function documentation.
  """
  @impl GenServer
  def handle_call({:deposit, amount, currency}, _from, state) do
    balance = state[currency] || 0
    new_state = %{currency => balance + amount}
    {:reply, {:ok, new_state[currency]}, new_state}
  end

  @doc """
  Callback from GenServer implementing the withdraw logic.
  Examples on the AccountServer.call function documentation.
  """
  @impl GenServer
  def handle_call({:withdraw, amount, currency}, _from, state) do
    balance = state[currency] || 0
    new_balance = balance - amount

    if new_balance >= 0 do
      new_state = Map.merge(state, %{currency => new_balance})
      {:reply, {:ok, new_state[currency]}, new_state}
    else
      {:reply, {:error, :not_enough_money, :withdraw}, state}
    end
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
  @spec spawn_account(user :: String.t()) :: {:ok, pid()} | {:error, {:already_started, pid()}}
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

      iex> AccountServer.spawn_account("Jeff")
      ...> AccountServer.call("Jeff", {:deposit, 100, "USD"})
      ...> AccountServer.call("Jeff", {:withdraw, 10, "USD"})
      {:ok, 90}

  """
  @spec call(user :: String.t(), action_options :: tuple(), options :: list()) ::
          {:ok, number()} | {:error, atom(), atom()}
  def call(user, action_options, options \\ []) when is_list(options) do
    defaults = [skip_queue_limit: false]
    options = Keyword.merge(defaults, options)

    pid = process_id(user)
    operation = elem(action_options, 0)

    cond do
      !is_pid(pid) ->
        {:error, :process_not_found, operation}

      !options[:skip_queue_limit] && mailbox_full?(pid) ->
        {:error, :process_mailbox_is_full, operation}

      true ->
        GenServer.call(pid, action_options)
    end
  end

  defp mailbox_full?(pid) do
    process = Application.get_env(:ex_banking, :process_module, Process)
    {:message_queue_len, queue_size} = process.info(pid, :message_queue_len)
    queue_size >= @process_mailbox_limit
  end

  defp process_id(user) do
    user
    |> process_name()
    |> Process.whereis()
  end

  defp process_name(user) do
    String.to_atom(user <> "Account")
  end
end
