defmodule Lexer do
  @moduledoc """
  Documentation for `Lexer`.
  """

  defmodule Token do
    defstruct type: :undefined, text: nil

    @type token_type ::
            :undefined
            | :null
            | :integer
            | :float
            | :boolean
            | :string
            | :lbrace
            | :rbrace
            | :lbracket
            | :rbracket
            | :lparen
            | :rparen
            | :comma

    @type t :: %Token{type: token_type, text: binary | nil}
  end

  @group_syms %{
    ?{ => :lbrace,
    ?} => :rbrace,
    ?[ => :lbracket,
    ?] => :rbracket,
    ?( => :lparen,
    ?) => :rparen,
    ?, => :comma
  }

  @spec tokenize(binary, list(Token)) :: {:ok, list(Token)} | {:error, binary}
  def tokenize(str, tokens \\ [])

  def tokenize("", tokens), do: {:ok, Enum.reverse(tokens)}

  def tokenize(<<"undefined", rest::binary>>, tokens) do
    tokenize(rest, [%Token{type: :undefined, text: nil} | tokens])
  end

  def tokenize(<<"null", rest::binary>>, tokens) do
    tokenize(rest, [%Token{type: :null, text: nil} | tokens])
  end

  def tokenize(<<"true", rest::binary>>, tokens) do
    tokenize(rest, [%Token{type: :boolean, text: "true"} | tokens])
  end

  def tokenize(<<"false", rest::binary>>, tokens) do
    tokenize(rest, [%Token{type: :boolean, text: "false"} | tokens])
  end

  def tokenize(<<top, rest::binary>>, tokens) do
    try do
      {new_rest, new_tokens} =
        case top do
          ?\s ->
            {rest, tokens}

          ?" ->
            tokenize_string(rest, tokens, [])

          c when c in ?0..?9 ->
            tokenize_number(rest, tokens, [c])

          c ->
            if c in Map.keys(@group_syms) do
              {rest, [%Token{type: @group_syms[c], text: nil} | tokens]}
            else
              throw(:unrecognized_character)
            end
        end

      tokenize(new_rest, new_tokens)
    catch
      :unrecognized_character -> {:error, "unrecognized character"}
    end
  end

  @spec tokenize_number(binary, list(Token), charlist) :: {binary, list(Token)}
  defp tokenize_number(str, tokens, current_token)

  defp tokenize_number(<<a, rest::binary>>, tokens, current_token)
       when a in ?0..?9 or a == ?. do
    tokenize_number(rest, tokens, [a | current_token])
  end

  defp tokenize_number(str, tokens, current_token) do
    token_type =
      if ?. in current_token do
        :float
      else
        :integer
      end

    token_text = current_token |> Enum.reverse() |> to_string

    {str, [%Token{type: token_type, text: token_text} | tokens]}
  end

  @spec tokenize_string(binary, list(Token), charlist) :: {binary, list(Token)}
  defp tokenize_string(str, tokens, current_token)

  # Closing quote
  defp tokenize_string(<<?", rest::binary>>, tokens, current_token) do
    token_text = current_token |> Enum.reverse() |> to_string
    {rest, [%Token{type: :string, text: token_text} | tokens]}
  end

  defp tokenize_string(<<c, rest::binary>>, tokens, current_token) do
    tokenize_string(rest, tokens, [c | current_token])
  end
end
