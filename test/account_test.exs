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
      assert Account.get_balance("Sarah", "USD") == {:ok, 0.0}
    end

    test "it returns an error when the user don't exist" do
      assert Account.get_balance("Santa Claus", "USD") == {:error, :user_does_not_exist}
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
  end
end
