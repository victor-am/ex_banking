defmodule AccountTest do
  use ExUnit.Case
  alias ExBanking.Account
  doctest Account

  describe "create_user/1" do
    test "returns :ok" do
      assert Account.create_user("Erik") == :ok
    end

    test "returns an error when the user already exists" do
      Account.create_user("Eliot")
      assert Account.create_user("Eliot") == {:error, :user_already_exists}
    end
  end

  describe "get_balance/2" do
    test "returns the balance of the given user" do
      Account.create_user("Sarah")
      assert Account.get_balance("Sarah", "USD") == {:ok, 0}
    end

    test "returns an error when the user don't exist" do
      assert Account.get_balance("Santa Claus", "USD") == {:error, :user_does_not_exist}
    end

    test "returns an error when the account operation queue is full" do
      Account.create_user("Yara")
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:get_balance, "USD"}),
          do: {:error, :process_mailbox_is_full, :get_balance}
      end

      assert Account.get_balance("Yara", "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_user}
    end
  end

  describe "deposit/3" do
    test "returns the user balance as an integer containing the decimal places" do
      Account.create_user("Liliana")
      assert Account.deposit("Liliana", 10150, "USD") == {:ok, 10150}
    end

    test "returns an error when the user don't exist" do
      assert Account.deposit("Santa Claus", 10000, "USD") == {:error, :user_does_not_exist}
    end

    test "returns an error when the account operation queue is full" do
      Account.create_user("Yennifer")
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:deposit, 100, "USD"}), do: {:error, :process_mailbox_is_full, :deposit}
      end

      assert Account.deposit("Yennifer", 100, "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_user}
    end
  end

  describe "withdraw/3" do
    test "returns the user balance as an integer containing the decimal places" do
      Account.create_user("Gideon")
      Account.deposit("Gideon", 15000, "USD")
      assert Account.withdraw("Gideon", 5000, "USD") == {:ok, 10000}
    end

    test "returns an error when the user don't exist" do
      assert Account.withdraw("Santa Claus", 10000, "USD") == {:error, :user_does_not_exist}
    end

    test "returns an error when the account operation queue is full" do
      Account.create_user("Leo")
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:withdraw, 100, "USD"}),
          do: {:error, :process_mailbox_is_full, :withdraw}
      end

      assert Account.withdraw("Leo", 100, "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_user}
    end

    test "returns an error when there is not enough money in the account" do
      Account.create_user("Sam")
      assert Account.withdraw("Sam", 99999, "USD") == {:error, :not_enough_money}
    end
  end

  describe "send/4" do
    test "returns the user balance as an integer containing the decimal places" do
      Account.create_user("Cleo")
      Account.create_user("Mikhail")
      Account.deposit("Cleo", 15000, "USD")
      assert Account.send("Cleo", "Mikhail", 5000, "USD") == {:ok, 10000, 5000}
    end

    test "returns an error when the sender don't exist" do
      Account.create_user("Lincoln")

      assert Account.send("Santa Claus", "Lincoln", 10000, "USD") ==
               {:error, :sender_does_not_exist}
    end

    test "returns an error when the receiver don't exist and keeps the sender balance" do
      Account.create_user("Joe")
      Account.deposit("Joe", 10000, "USD")

      assert Account.send("Joe", "Santa Claus", 10000, "USD") ==
               {:error, :receiver_does_not_exist}

      assert Account.get_balance("Joe", "USD") == {:ok, 10000}
    end

    test "returns an error when the sender account operation queue is full" do
      Account.create_user("Aron")
      Account.create_user("Fausto")
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call(_user, {:withdraw, 100, "USD"}),
          do: {:error, :process_mailbox_is_full, :withdraw}
      end

      assert Account.send("Aron", "Fausto", 100, "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_sender}
    end

    test "returns an error when the receiver account operation queue is full" do
      Account.create_user("Lily")
      Account.create_user("Margarida")
      # This simulates a :process_mailbox_is_full error
      defmodule AccountServerStub do
        def call("Lily", {:withdraw, 100, "USD"}),
          do: {:ok, 0}

        def call("Margarida", {:deposit, 100, "USD"}),
          do: {:error, :process_mailbox_is_full, :deposit}

        # Rollback after deposit failure
        def call("Lily", {:deposit, 100, "USD"}, skip_queue_limit: true),
          do: {:ok, 100}
      end

      assert Account.send("Lily", "Margarida", 100, "USD", AccountServerStub) ==
               {:error, :too_many_requests_to_receiver}
    end

    test "returns an error when there is not enough money in the account" do
      Account.create_user("Jade")
      Account.create_user("Akemi")
      assert Account.send("Jade", "Akemi", 99999, "USD") == {:error, :not_enough_money}
    end
  end
end
