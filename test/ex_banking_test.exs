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
end
