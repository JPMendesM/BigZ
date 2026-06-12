defmodule Bigz.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "habits" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :points, :integer

    belongs_to :user, Bigz.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for creating or updating a habit.
  """
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :description, :category, :points, :user_id])
    |> validate_required([:name, :category, :points, :user_id])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_number(:points, greater_than: 0)
    |> validate_inclusion(:category, ["alimentação", "transporte", "energia", "água", "resíduos"])
  end
end
