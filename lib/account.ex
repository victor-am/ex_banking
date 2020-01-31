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

      iex> ExBanking.Account.create_user("Anna")
      :ok

      iex> ExBanking.Account.create_user("Olivia")
      ...> ExBanking.Account.create_user("Olivia")
      {:error, :user_already_exists}

  """
  def create_user(user) do
    case AccountServer.spawn_account(user) do
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
      {:ok, _pid} -> :ok
    end
  end
end
