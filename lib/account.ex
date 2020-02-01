defmodule ExBanking.Account do
  @moduledoc """
  The Account module is responsible for handling interactions between the
  ExBanking functions and the GenServer implemented in AccountServer.

  It handles some business logic while also translating the low-level messages
  from AccountServer to business messages that ExBanking can actually return.
  """
  alias ExBanking.AccountServer

  @doc """
  Creates a new AccountServer process using the given name (case-sensitive string),
  unless there is already a process using the same user name.

  Returns `:ok`

  ## Examples

      iex> Account.create_user("Anna")
      :ok

      iex> Account.create_user("Olivia")
      ...> Account.create_user("Olivia")
      {:error, :user_already_exists}

  """
  def create_user(user) do
    case AccountServer.spawn_account(user) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
    end
  end

  @doc """
  Gets the current amount of money a user has on the given currency.

  Returns `{:ok, balance}`

  ## Examples

      iex> Account.create_user("Tod")
      iex> Account.get_balance("Tod", "USD")
      {:ok, 0}

      iex> Account.get_balance("Santa Claus", "USD")
      {:error, :user_does_not_exist}

  """
  def get_balance(user, currency, account_server_module \\ AccountServer) do
    case account_server_module.call(user, {:get_balance, currency}) do
      {:ok, balance} -> {:ok, balance}
      {:error, :process_not_found} -> {:error, :user_does_not_exist}
      {:error, :process_mailbox_is_full} -> {:error, :too_many_requests_to_user}
    end
  end

  @doc """
  Adds the given amount of money from the given currency to the specified user account.

  Returns `{:ok, balance}`

  ## Examples

      iex> Account.create_user("Susan")
      ...> Account.deposit("Susan", 1042, "USD")
      {:ok, 1042}

      iex> Account.deposit("Santa Claus", 1050, "USD")
      {:error, :user_does_not_exist}

  """
  def deposit(user, amount, currency, account_server_module \\ AccountServer) do
    case account_server_module.call(user, {:deposit, amount, currency}) do
      {:ok, balance} -> {:ok, balance}
      {:error, :process_not_found} -> {:error, :user_does_not_exist}
      {:error, :process_mailbox_is_full} -> {:error, :too_many_requests_to_user}
    end
  end
end
