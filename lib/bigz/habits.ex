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

  @doc """
  Returns the total number of habits available in the catalog.
  """
  def count_habits(_current_scope \\ nil) do
    Repo.aggregate(Habit, :count, :id)
  end

  @doc """
  Returns the number of habits created by the user in the given scope.
  """
  def count_user_habits(current_scope) do
    user_id = current_scope.user.id
    Repo.aggregate(from(h in Habit, where: h.user_id == ^user_id), :count, :id)
  end

  @doc """
  Returns the total number of check-ins registered by the user in the given scope.
  """
  def count_user_checkins(current_scope) do
    user_id = current_scope.user.id
    Repo.aggregate(from(c in Checkin, where: c.user_id == ^user_id), :count, :id)
  end

  @doc """
  Returns the number of check-ins the user registered today (UTC).
  """
  def count_user_checkins_today(current_scope) do
    user_id = current_scope.user.id
    today = Date.utc_today()

    Repo.aggregate(
      from(c in Checkin, where: c.user_id == ^user_id and c.checkin_date == ^today),
      :count,
      :id
    )
  end
end
