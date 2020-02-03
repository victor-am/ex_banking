defmodule ExBanking.Money do
  @moduledoc """
  The functions inside this module are used to convert money between integer and
  2 decimal places float formats.
  """
  def to_float(integer_amount) do
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
