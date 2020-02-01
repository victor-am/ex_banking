defmodule ExBanking.Money do
  @moduledoc """
  The functions inside this module are used to convert money between integer and
  2 decimal places float formats. More information about this implementation
  choice on the README.
  """
  def to_decimal(integer_amount) do
    integer_amount / 100
  end

  def to_integer(amount) when is_float(amount) do
    amount
    |> Kernel.*(100)
    |> trunc()
  end

  def to_integer(amount) when is_integer(amount) do
    amount * 100
  end
end
