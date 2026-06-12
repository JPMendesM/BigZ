defmodule Bigz.Habits do
  @moduledoc """
  The Habits context.
  """

  import Ecto.Query, warn: false
  alias Bigz.Repo
  alias Bigz.Habits.Checkin
  alias Bigz.Habits.Habit

  @doc """
  Returns the list of habits.

  Optionally filters by category.
  """
  def list_habits(_current_scope, filters \\ %{}) do
    query = from h in Habit, preload: [:user], order_by: [desc: h.inserted_at]

    query =
      case Map.get(filters, "category") do
        cat when cat in ["alimentação", "transporte", "energia", "água", "resíduos"] ->
          from h in query, where: h.category == ^cat

        _ ->
          query
      end

    Repo.all(query)
  end

  @doc """
  Gets a single habit.

  Raises `Ecto.NoResultsError` if the Habit does not exist.
  """
  def get_habit!(_current_scope, id) do
    Repo.get!(Habit, id) |> Repo.preload(:user)
  end

  @doc """
  Creates a habit.
  """
  def create_habit(current_scope, attrs \\ %{}) do
    %Habit{user_id: current_scope.user.id}
    |> Habit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a habit.

  Only the creator of the habit is authorized to update it.
  """
  def update_habit(current_scope, %Habit{} = habit, attrs) do
    if habit.user_id == current_scope.user.id do
      habit
      |> Habit.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a habit.

  Only the creator of the habit is authorized to delete it.
  """
  def delete_habit(current_scope, %Habit{} = habit) do
    if habit.user_id == current_scope.user.id do
      Repo.delete(habit)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the habit.
  """
  def change_habit(_current_scope, %Habit{} = habit, attrs \\ %{}) do
    Habit.changeset(habit, attrs)
  end

  @doc """
  Registers a check-in for the authenticated user on the given habit for today.

  `checkin_date` is set server-side via `Date.utc_today/0`; "same day" is
  evaluated in UTC. No user-supplied date or user_id is accepted.

  Returns `{:ok, checkin}` on success or `{:error, changeset}` on failure.
  The changeset error message for a duplicate is "Você já registrou este hábito hoje."
  """
  def create_checkin(current_scope, %Habit{} = habit) do
    %Checkin{
      user_id: current_scope.user.id,
      habit_id: habit.id,
      checkin_date: Date.utc_today()
    }
    |> Checkin.changeset(%{})
    |> Repo.insert()
  end
end
