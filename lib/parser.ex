defmodule Parser do
  @moduledoc """
  Documentation for `Parser`.
  """

  alias Lexer.Token

  defmodule ASTNode do
    defstruct type: :undefined, value: nil, children: []

    @type node_type ::
            :undefined
            | :null
            | :integer
            | :float
            | :boolean
            | :string
            | :array
            | :object
            | :kv_pair

    @type t :: %ASTNode{type: node_type, value: any, children: list(t)}
    @type keyvalue_pair :: %ASTNode{
            type: :kv_pair,
            value: nil,
            children: nonempty_list(t)
          }
    @type object :: %ASTNode{type: :object, value: nil, children: list(keyvalue_pair)}
  end

  @type parser_state :: {:ok, ASTNode.t(), list(Lexer.Token.t())} | {:error, binary}

  @doc "Helper function for creating ASTNode struct"
  def node(type, value \\ nil, children \\ []) do
    %ASTNode{type: type, value: value, children: children}
  end

  @spec parse(list(Lexer.Token.t())) :: {:ok, ASTNode.t()} | {:error, binary}
  def parse(tokens)

  def parse([]), do: {:error, "empty token list"}

  def parse(tokens) do
    with {:ok, node, []} <- parse_expr(tokens) do
      deserialize_ast(node)
    else
      {:ok, _, rem} -> {:error, "token list not fully consumed: #{inspect(rem)}"}
    end
  end

  def deserialize_ast(node) do
    case node do
      %ASTNode{value: v, children: []} ->
        {:ok, v}

      %ASTNode{type: :array, children: elements} ->
        # compute child ASTNode in own tasks
        array =
          elements
          |> Enum.map(
            &Task.async(fn ->
              {:ok, v} = deserialize_ast(&1)
              v
            end)
          )
          |> Task.await_many()

        {:ok, array}

      %ASTNode{type: :kv_pair, children: kv} ->
        kvpair =
          kv
          |> Enum.map(
            &Task.async(fn ->
              {:ok, v} = deserialize_ast(&1)
              v
            end)
          )
          |> Task.await_many()

        {:ok, kvpair}

      %ASTNode{type: :object, children: kvpairs} ->
        map =
          kvpairs
          |> Enum.map(
            &Task.async(fn ->
              {:ok, [k, v]} = deserialize_ast(&1)
              {k, v}
            end)
          )
          |> Task.await_many()
          |> Enum.into(%{}, fn {k, v} ->
            k = if is_binary(k), do: String.to_atom(k), else: k
            {k, v}
          end)

        {:ok, map}
    end
  end

  @spec parse_expr(list(Lexer.Token.t())) :: parser_state
  defp parse_expr(tokens) do
    case tokens do
      [%Token{type: :lbracket} | tokens] -> parse_array(tokens)
      [%Token{type: :lbrace} | tokens] -> parse_object(tokens)
      _ -> parse_literal(tokens)
    end
  end

  @spec parse_literal(list(Lexer.Token.t())) :: parser_state
  defp(parse_literal([token | rest])) do
    %Token{type: t, text: v} = token

    node =
      case t do
        :integer -> %ASTNode{type: :integer, value: String.to_integer(v)}
        :float -> %ASTNode{type: :float, value: String.to_float(v)}
        :boolean -> %ASTNode{type: :boolean, value: v == "true"}
        :string -> %ASTNode{type: :string, value: v}
        :null -> %ASTNode{type: :null}
        :undefined -> %ASTNode{type: :undefined, value: :undefined}
      end

    {:ok, node, rest}
  end

  @spec parse_array(list(Lexer.Token.t()), ASTNode.t()) :: parser_state
  defp parse_array(tokens, array_node \\ %ASTNode{type: :array})

  defp parse_array([], _array_node), do: {:error, "unclosed array"}

  defp parse_array(tokens, array_node) do
    with {:ok, element, rest} <- parse_expr(tokens) do
      new_array_node = %{array_node | children: [element | array_node.children]}

      case rest do
        [] ->
          {:error, "unclosed array"}

        [%Token{type: :rbracket} | new_rest] ->
          final_array_node = %{new_array_node | children: Enum.reverse(new_array_node.children)}
          {:ok, final_array_node, new_rest}

        [%Token{type: :comma} | new_rest] ->
          parse_array(new_rest, new_array_node)

        [token | _new_rest] ->
          {:error, "unexpected token encountered while parsing array: #{inspect(token)}"}
      end
    end
  end

  @spec parse_object(list(Lexer.Token.t()), ASTNode.object()) :: parser_state
  defp parse_object(tokens, object_node \\ %ASTNode{type: :object})

  defp parse_object([], _object_node), do: {:error, "unclosed object"}

  defp parse_object(tokens, object_node) do
    with {:ok, key, rest} <- parse_expr(tokens),
         [%Token{type: :colon} | intermediate_rest] = rest,
         {:ok, value, new_rest} <- parse_expr(intermediate_rest) do
      kv_pair_node = %ASTNode{type: :kv_pair, children: [key, value]}
      new_object_node = %{object_node | children: [kv_pair_node | object_node.children]}

      case new_rest do
        [] ->
          {:error, "unclosed object"}

        [%Token{type: :rbrace} | new_rest] ->
          {:ok, new_object_node, new_rest}

        [%Token{type: :comma} | new_rest] ->
          parse_object(new_rest, new_object_node)

        [token | _new_rest] ->
          {:error, "unexpected token encountered while parsing object: #{inspect(token)}"}
      end
    else
      e -> {:error, "unexpected parser state encountered while parsing object: #{inspect(e)}"}
    end
  end
end
