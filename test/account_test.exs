defmodule AccountTest do
  use ExUnit.Case
  alias ExBanking.Account
  doctest Account

  describe "create_user/1" do
    test "it returns :ok" do
      assert Account.create_user("Erik") == :ok
    end

    test "it returns an error when the user already exists" do
      Account.create_user("Eliot")
      assert Account.create_user("Eliot") == {:error, :user_already_exists}
    end
  end

  describe "get_balance/2" do
    test "it returns the balance of the given user" do
      Account.create_user("Sarah")
      assert Account.get_balance("Sarah", "USD") == {:ok, 0}
    end

    test "it returns an error when the user don't exist" do
      assert Account.get_balance("Santa Claus", "USD") == {:error, :user_does_not_exist}
    end

    test "it returns an error when the account operation queue is full" do
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:get_balance, "USD"}), do: {:error, :process_mailbox_is_full}
      end

      assert Account.get_balance("Yara", "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_user}
    end
  end

  describe "deposit/3" do
    test "it returns the user balance as an integer containing the decimal places" do
      Account.create_user("Liliana")
      assert Account.deposit("Liliana", 10150, "USD") == {:ok, 10150}
    end

    test "it returns an error when the user don't exist" do
      assert Account.deposit("Santa Claus", 10000, "USD") == {:error, :user_does_not_exist}
    end

    test "it returns an error when the account operation queue is full" do
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:deposit, 100, "USD"}), do: {:error, :process_mailbox_is_full}
      end

      assert Account.deposit("Yara", 100, "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_user}
    end
  end

  describe "withdraw/3" do
    test "it returns the user balance as an integer containing the decimal places" do
      Account.create_user("Gideon")
      Account.deposit("Gideon", 15000, "USD")
      assert Account.withdraw("Gideon", 5000, "USD") == {:ok, 10000}
    end

    test "it returns an error when the user don't exist" do
      assert Account.withdraw("Santa Claus", 10000, "USD") == {:error, :user_does_not_exist}
    end

    test "it returns an error when the account operation queue is full" do
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:withdraw, 100, "USD"}), do: {:error, :process_mailbox_is_full}
      end

      assert Account.withdraw("Yara", 100, "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_user}
    end

    test "it returns an error when there is not enough money in the account" do
      Account.create_user("Sam")
      assert Account.withdraw("Sam", 99999, "USD") == {:error, :not_enough_money}
    end
  end
end
