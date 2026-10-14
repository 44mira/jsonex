defmodule Parser do
  @moduledoc """
  Documentation for `Parser`.
  """

  alias Lexer.Token

  @spec parse(list(Lexer.Token)) :: {:ok, any} | {:error, binary}
  def parse(tokens)

  def parse([]), do: {:error, "empty token list"}

  def parse([root | _rest]) do
    parse_token(root)
  end

  defp parse_token(%Token{type: t, text: v}) do
    value =
      case t do
        :integer -> String.to_integer(v)
        :float -> String.to_float(v)
        :string -> v
        :boolean -> v == "true"
        :null -> nil
        :undefined -> :undefined
        _ -> :error
      end

    unless value == :error do
      {:ok, value}
    else
      {:error, "unrecognized token"}
    end
  end
end
