defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  defp tokenize(str) do
    {:ok, tokens} = Lexer.tokenize(str)
    tokens
  end

  test "Parse numbers" do
    assert Parser.parse(tokenize("123")) === {:ok, 123}
    assert Parser.parse(tokenize("4.2")) === {:ok, 4.2}
  end

  test "Parse strings" do
    assert Parser.parse(tokenize(~s|"hello world"|)) === {:ok, "hello world"}
  end

  test "Parse booleans" do
    assert Parser.parse(tokenize("true")) === {:ok, true}
    assert Parser.parse(tokenize("false")) === {:ok, false}
  end

  test "Parse null and undefined" do
    assert Parser.parse(tokenize("null")) === {:ok, nil}
    assert Parser.parse(tokenize("undefined")) === {:ok, :undefined}
  end

  test "Parse array" do
    assert Parser.parse(tokenize("[1, 2, 3]")) === {:ok, [1, 2, 3]}
  end

  test "Parse nested array" do
    assert Parser.parse(tokenize("[1, [2, 3], [[4]]]")) === {:ok, [1, [2, 3], [[4]]]}
  end

  test "Parse map" do
    assert Parser.parse(tokenize(~s|{"name": "benson", "age": 23}|)) ===
             {:ok,
              %{
                name: "benson",
                age: 23
              }}
  end

  test "Parse nested map" do
    input_str = ~s|
      {
        "name": {"first": "gerard benson", "last": "cabading"},
        "age": 23,
        "hobbies": ["videogames", "movies", "anime"],
        "bitches": null
      }|

    assert Parser.parse(tokenize(input_str)) ===
             {:ok,
              %{
                name: %{first: "gerard benson", last: "cabading"},
                age: 23,
                hobbies: ["videogames", "movies", "anime"],
                bitches: nil
              }}
  end

  # TODO: handle compound types
end
