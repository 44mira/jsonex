defmodule Jsonex do
  @moduledoc """
  Documentation for `Jsonex`.
  """

  def deserialize(str) do
    with {:ok, tokens} <- Lexer.tokenize(str) do
      Parser.parse(tokens)
    end
  end
end
