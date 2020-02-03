defmodule ExBanking do
  @moduledoc """
  The ExBanking module serves as an entrypoint for the application, it's APIs
  are the only things meant to be directly exposed to the outside world.

  It's a very thin layer of the application, mostly just calling Account module
  methods instead of doing much on it's own.
  """
  alias ExBanking.Account
  alias ExBanking.Money

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
    with true <- is_binary(user) do
      Account.create_user(user)
    else
      false -> {:error, :wrong_arguments}
    end
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
    with true <- is_binary(user),
         true <- is_binary(currency) do
      user
      |> Account.get_balance(currency)
      |> convert_to_money_to_float
    else
      false -> {:error, :wrong_arguments}
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
    with true <- is_binary(user),
         true <- is_number(amount),
         true <- is_binary(currency) do
      user
      |> Account.deposit(Money.to_integer(amount), currency)
      |> convert_to_money_to_float
    else
      false -> {:error, :wrong_arguments}
    end
  end

  @doc """
  Removes the given amount of money from the given currency from the specified user account.

  Returns `{:ok, balance}`

  ## Examples

      iex> ExBanking.create_user("Terry")
      ...> ExBanking.deposit("Terry", 150.50, "USD")
      ...> ExBanking.withdraw("Terry", 25.50, "USD")
      {:ok, 125.0}

      iex> ExBanking.withdraw("Santa Claus", 10.50, "USD")
      {:error, :user_does_not_exist}

  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    with true <- is_binary(user),
         true <- is_number(amount),
         true <- is_binary(currency) do
      user
      |> Account.withdraw(Money.to_integer(amount), currency)
      |> convert_to_money_to_float
    else
      false -> {:error, :wrong_arguments}
    end
  end

  @doc """
  Transfers an amount of money of a given currency from one user account to another.

  Returns `{:ok, sender_balance, receiver_balance}`

  ## Examples

      iex> ExBanking.create_user("Jose")
      ...> ExBanking.create_user("Amelia")
      ...> ExBanking.deposit("Jose", 150.0, "USD")
      ...> ExBanking.send("Jose", "Amelia", 50.0, "USD")
      {:ok, 100.0, 50.0}

  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    with true <- is_binary(from_user),
         true <- is_binary(to_user),
         true <- is_number(amount),
         true <- is_binary(currency) do
      from_user
      |> Account.send(to_user, Money.to_integer(amount), currency)
      |> convert_to_money_to_float
    else
      false -> {:error, :wrong_arguments}
    end
  end

  defp convert_to_money_to_float(response) do
    case response do
      {:ok, amount} -> {:ok, Money.to_float(amount)}
      {:ok, amount_a, amount_b} -> {:ok, Money.to_float(amount_a), Money.to_float(amount_b)}
      {:error, message} -> {:error, message}
    end
  end
end
