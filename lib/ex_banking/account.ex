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
      {:error, :process_not_found, _} -> {:error, :user_does_not_exist}
      {:error, :process_mailbox_is_full, _} -> {:error, :too_many_requests_to_user}
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
      {:error, :process_not_found, _} -> {:error, :user_does_not_exist}
      {:error, :process_mailbox_is_full, _} -> {:error, :too_many_requests_to_user}
    end
  end

  @doc """
  Removes the given amount of money from the given currency from the specified user account.

  Returns `{:ok, balance}`

  ## Examples

      iex> Account.create_user("Marco")
      ...> Account.deposit("Marco", 100, "USD")
      ...> Account.withdraw("Marco", 50, "USD")
      {:ok, 50}

      iex> Account.withdraw("Santa Claus", 1050, "USD")
      {:error, :user_does_not_exist}

  """
  def withdraw(user, amount, currency, account_server_module \\ AccountServer) do
    case account_server_module.call(user, {:withdraw, amount, currency}) do
      {:ok, balance} -> {:ok, balance}
      {:error, :process_not_found, _} -> {:error, :user_does_not_exist}
      {:error, :process_mailbox_is_full, _} -> {:error, :too_many_requests_to_user}
      {:error, :not_enough_money, _} -> {:error, :not_enough_money}
    end
  end

  @doc """
  Transfers an amount of money of a given currency from one user account to another.
  It basically runs a withdraw followed by a deposit, handling any rollback in case
  a operation fails.

  Returns `{:ok, sender_balance, receiver_balance}`

  ## Examples

      iex> Account.create_user("Denis")
      ...> Account.create_user("Camila")
      ...> Account.deposit("Denis", 150, "USD")
      ...> Account.send("Denis", "Camila", 50, "USD")
      {:ok, 100, 50}

  """
  def send(from_user, to_user, amount, currency, account_server_module \\ AccountServer) do
    with {:ok, from_user_balance} <-
           account_server_module.call(from_user, {:withdraw, amount, currency}),
         {:ok, to_user_balance} <-
           account_server_module.call(to_user, {:deposit, amount, currency}) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:error, :process_not_found, :withdraw} ->
        {:error, :sender_does_not_exist}

      {:error, :process_mailbox_is_full, :withdraw} ->
        {:error, :too_many_requests_to_sender}

      {:error, :not_enough_money, :withdraw} ->
        {:error, :not_enough_money}

      # When the operation fails in the deposit phase we should rollback the
      # withdraw to avoid inconsistencies. The [skip_queue_limit: true] is important
      # to allow the rollback operation to proceed even if the message queue is full.
      {:error, :process_not_found, :deposit} ->
        account_server_module.call(from_user, {:deposit, amount, currency}, skip_queue_limit: true)

        {:error, :receiver_does_not_exist}

      {:error, :process_mailbox_is_full, :deposit} ->
        account_server_module.call(from_user, {:deposit, amount, currency}, skip_queue_limit: true)

        {:error, :too_many_requests_to_receiver}
    end
  end
end
