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
      assert ExBanking.get_balance("Sarah", "USD") == {:ok, 0.00}
    end

    test "it returns an error when the user don't exist" do
      assert ExBanking.get_balance("Santa Claus", "USD") == {:error, :user_does_not_exist}
    end
  end

  describe "deposit/3" do
    test "it accepts both floats and integers as amounts" do
      ExBanking.create_user("Julian")
      assert ExBanking.deposit("Julian", 100, "USD") == {:ok, 100.00}
      assert ExBanking.deposit("Julian", 1.50, "USD") == {:ok, 101.50}
    end

    test "it returns an error when the user don't exist" do
      assert ExBanking.deposit("Santa Claus", 100, "USD") == {:error, :user_does_not_exist}
    end
  end

  describe "withdraw/3" do
    test "it accepts both floats and integers as amounts" do
      ExBanking.create_user("Tristan")
      ExBanking.deposit("Tristan", 200.0, "USD")
      assert ExBanking.withdraw("Tristan", 150, "USD") == {:ok, 50.0}
      assert ExBanking.withdraw("Tristan", 25.50, "USD") == {:ok, 24.50}
    end

    test "it returns an error when the user don't exist" do
      assert ExBanking.withdraw("Santa Claus", 100, "USD") == {:error, :user_does_not_exist}
    end

    test "it returns an error when there is not enough money in the account" do
      ExBanking.create_user("Rie")
      assert ExBanking.withdraw("Rie", 100.0, "USD") == {:error, :not_enough_money}
    end
  end

  describe "send/4" do
    test "it accepts both floats and integers as amounts" do
      ExBanking.create_user("Tommy")
      ExBanking.create_user("Tanaka")
      ExBanking.deposit("Tommy", 200.0, "USD")
      assert ExBanking.send("Tommy", "Tanaka", 150, "USD") == {:ok, 50.0, 150.0}
      assert ExBanking.send("Tanaka", "Tommy", 150, "USD") == {:ok, 0.0, 200.0}
    end

    test "it returns an error when the sender don't exist" do
      ExBanking.create_user("Paul")

      assert ExBanking.send("Santa Claus", "Paul", 100, "USD") ==
               {:error, :sender_does_not_exist}
    end

    test "it returns an error when there is not enough money in the account" do
      ExBanking.create_user("Adam")
      ExBanking.create_user("Eve")
      assert ExBanking.send("Adam", "Eve", 100.0, "USD") == {:error, :not_enough_money}
    end
  end
end
