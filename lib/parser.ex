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

    @type t :: %ASTNode{type: node_type, value: any, children: list(ASTNode.t())}
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
      {:ok, _, rem} -> {:error, "token list not fully consumed: #{rem}"}
    end
  end

  # TODO: Deserialize Arrays and Objects
  def deserialize_ast(node) do
    case node do
      %ASTNode{value: v, children: []} ->
        {:ok, v}

      %ASTNode{type: :array, children: elements} ->
        array =
          elements
          |> Enum.map(&deserialize_ast/1)
          |> Enum.map(fn {:ok, v} -> v end)

        {:ok, array}
    end
  end

  @spec parse_expr(list(Lexer.Token.t())) :: parser_state
  defp parse_expr(tokens) do
    case tokens do
      [%Token{type: :lbracket} | tokens] -> parse_array(tokens)
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
        [%Token{type: :rbracket} | new_rest] ->
          final_array_node = %{new_array_node | children: Enum.reverse(new_array_node.children)}
          {:ok, final_array_node, new_rest}

        [%Token{type: :comma} | new_rest] ->
          parse_array(new_rest, new_array_node)

        [token | _new_rest] ->
          {:error, "unexpected token encountered while parsing array: #{token}"}
      end
    end
  end
end
