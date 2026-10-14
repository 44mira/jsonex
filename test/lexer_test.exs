defmodule LexerTest do
  use ExUnit.Case
  doctest Lexer

  defp token(type, text \\ nil), do: %Lexer.Token{type: type, text: text}

  test "Tokenize empty" do
    assert Lexer.tokenize("") == {:ok, []}
  end

  test "Tokenize numbers" do
    assert Lexer.tokenize("42") == {:ok, [token(:integer, "42")]}
    assert Lexer.tokenize("42.0") == {:ok, [token(:float, "42.0")]}
  end

  test "Tokenize string" do
    assert Lexer.tokenize(~s|"Hello"|) == {:ok, [token(:string, "Hello")]}
  end

  test "Tokenize boolean" do
    assert Lexer.tokenize("true") == {:ok, [token(:boolean, "true")]}
    assert Lexer.tokenize("false") == {:ok, [token(:boolean, "false")]}
  end

  test "Tokenize undefined and null" do
    assert Lexer.tokenize("undefined") == {:ok, [token(:undefined)]}
    assert Lexer.tokenize("null") == {:ok, [token(:null)]}
  end

  test "Tokenize grouping characters" do
    assert Lexer.tokenize("{}()[],") ==
             {:ok,
              [
                token(:lbrace),
                token(:rbrace),
                token(:lparen),
                token(:rparen),
                token(:lbracket),
                token(:rbracket),
                token(:comma)
              ]}
  end

  test "Fail to tokenize unrecognized char" do
    assert Lexer.tokenize("?") == {:error, "unrecognized character"}
  end
end
