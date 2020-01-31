defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  describe "create_user/1" do
    test "it returns :ok" do
      assert ExBanking.create_user("Julia") == :ok
    end

    test "it returns an error when the user already exists" do
      ExBanking.create_user("Theodore")
      assert ExBanking.create_user("Theodore") == {:error, :user_already_exists}
    end
  end

  describe "get_balance/2" do
    test "it returns the balance of the given user" do
      ExBanking.create_user("Sarah")
      assert ExBanking.get_balance("Sarah", "USD") == {:ok, 0}
    end

    test "it returns an error when the user don't exist" do
      assert ExBanking.get_balance("Santa Claus", "USD") == {:error, :user_does_not_exist}
    end
  end
end
