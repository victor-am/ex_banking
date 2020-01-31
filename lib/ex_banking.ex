defmodule ExBanking do
  @moduledoc """
  The ExBanking module serves as an entrypoint for the application, it's APIs
  are the only things meant to be directly exposed to the outside world.

  It's a very thin layer of the application, mostly just calling Account module
  methods instead of doing much on it's own.
  """
  alias ExBanking.Account

  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  @doc """
  Creates a new user with a given name (case-sensitive string), unless there is
  already an user with the same name.

  Returns `:ok`

  ## Examples

      iex> ExBanking.create_user("John")
      :ok

      iex> ExBanking.create_user("Robert")
      ...> ExBanking.create_user("Robert")
      {:error, :user_already_exists}

  """
  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    Account.create_user(user)
  end

  @doc """
  Gets the current amount of money a user has on the given currency.

  Returns `{:ok, balance}`

  ## Examples

      iex> ExBanking.create_user("Elton")
      ...> ExBanking.get_balance("Elton", "USD")
      {:ok, 0.00}

      iex> ExBanking.get_balance("Santa Claus", "USD")
      {:error, :user_does_not_exist}

  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    case Account.get_balance(user, currency) do
      {:ok, balance} ->
        {:ok, money_to_decimal(balance)}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Adds the given amount of money from the given currency to the specified user account.

  Returns `{:ok, balance}`

  ## Examples

      iex> ExBanking.create_user("Evan")
      ...> ExBanking.deposit("Evan", 10.42, "USD")
      {:ok, 10.42}

      iex> ExBanking.deposit("Santa Claus", 10.50, "USD")
      {:error, :user_does_not_exist}

  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    case Account.deposit(user, money_to_integer(amount), currency) do
      {:ok, balance} ->
        {:ok, money_to_decimal(balance)}

      {:error, message} ->
        {:error, message}
    end
  end

  defp money_to_decimal(integer_amount) do
    integer_amount / 100
  end

  defp money_to_integer(amount) when is_float(amount) do
    amount
    |> Kernel.*(100)
    |> trunc()
  end

  defp money_to_integer(amount) when is_integer(amount) do
    amount * 100
  end
end
