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
end
