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
            | :list
            | :object

    @type t :: %ASTNode{type: node_type, value: any, children: list(ASTNode.t())}
  end

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

  def deserialize_ast(node) do
    case node do
      %ASTNode{value: v, children: []} -> {:ok, v}
    end
  end

  @spec parse_expr(list(Lexer.Token.t())) :: ASTNode.t()
  defp parse_expr(tokens) do
    parse_literal(tokens)
  end

  defp parse_literal([token | rest]) do
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
end
