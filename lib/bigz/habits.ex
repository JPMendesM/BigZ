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

  @community_topic "checkins:community"

  def community_topic, do: @community_topic

  @doc """
  Registers a check-in for the authenticated user on the given habit for today.
  """
  def create_checkin(current_scope, %Habit{} = habit) do
    result =
      %Checkin{
        user_id: current_scope.user.id,
        habit_id: habit.id,
        checkin_date: Date.utc_today()
      }
      |> Checkin.changeset(%{})
      |> Repo.insert()

    case result do
      {:ok, checkin} ->
        checkin = Repo.preload(checkin, [:user, :habit])
        Phoenix.PubSub.broadcast(Bigz.PubSub, @community_topic, {:new_checkin, checkin})
        {:ok, checkin}

      error ->
        error
    end
  end

  @doc """
  Returns the most recent check-ins from all users for the community feed.
  """
  def list_community_checkins(limit \\ 30) do
    Repo.all(
      from c in Checkin,
        join: u in assoc(c, :user),
        join: h in assoc(c, :habit),
        order_by: [desc: c.inserted_at],
        limit: ^limit,
        preload: [user: u, habit: h]
    )
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

  @doc """
  Returns the total points earned by the user across all their check-ins.
  """
  def sum_user_points(current_scope) do
    user_id = current_scope.user.id

    Repo.one(
      from c in Checkin,
        join: h in assoc(c, :habit),
        where: c.user_id == ^user_id,
        select: sum(h.points)
    ) || 0
  end

  @doc """
  Returns the points earned by the user in the current ISO week (Monday-Sunday, UTC).
  """
  def sum_user_points_this_week(current_scope) do
    user_id = current_scope.user.id
    {week_start, week_end} = current_week_range()

    Repo.one(
      from c in Checkin,
        join: h in assoc(c, :habit),
        where:
          c.user_id == ^user_id and
            c.checkin_date >= ^week_start and
            c.checkin_date <= ^week_end,
        select: sum(h.points)
    ) || 0
  end

  @doc """
  Returns the number of check-ins the user registered in the current ISO week (Monday-Sunday, UTC).
  """
  def count_user_checkins_this_week(current_scope) do
    user_id = current_scope.user.id
    {week_start, week_end} = current_week_range()

    Repo.aggregate(
      from(c in Checkin,
        where:
          c.user_id == ^user_id and
            c.checkin_date >= ^week_start and
            c.checkin_date <= ^week_end
      ),
      :count,
      :id
    )
  end

  @doc """
  Returns the user's check-ins ordered most recent first, with the associated habit preloaded.
  """
  def list_user_checkins(current_scope, limit \\ 50) do
    user_id = current_scope.user.id

    Repo.all(
      from c in Checkin,
        join: h in assoc(c, :habit),
        where: c.user_id == ^user_id,
        order_by: [desc: c.checkin_date, desc: c.inserted_at],
        limit: ^limit,
        preload: [habit: h]
    )
  end

  @doc """
  Returns a weekly summary of points and check-in count for the user's
  last `weeks` ISO weeks (Monday-Sunday, UTC), including the current week.

  Result is a chronological list of maps:
    %{week_start: ~D[...], points: integer, count: integer}
  """
  def list_weekly_summaries(current_scope, weeks \\ 6) do
    user_id = current_scope.user.id
    today = Date.utc_today()
    cur_week_start = Date.add(today, -(Date.day_of_week(today) - 1))
    since = Date.add(cur_week_start, -(weeks - 1) * 7)

    rows =
      Repo.all(
        from c in Checkin,
          join: h in assoc(c, :habit),
          where: c.user_id == ^user_id and c.checkin_date >= ^since,
          select: {c.checkin_date, h.points}
      )

    week_starts =
      Enum.map((weeks - 1)..0//-1, fn i -> Date.add(cur_week_start, -i * 7) end)

    by_week =
      Enum.group_by(rows, fn {date, _pts} ->
        Date.add(date, -(Date.day_of_week(date) - 1))
      end)

    Enum.map(week_starts, fn ws ->
      entries = Map.get(by_week, ws, [])

      %{
        week_start: ws,
        points: entries |> Enum.map(fn {_date, pts} -> pts end) |> Enum.sum(),
        count: length(entries)
      }
    end)
  end

  defp current_week_range do
    today = Date.utc_today()
    start = Date.add(today, -(Date.day_of_week(today) - 1))
    {start, Date.add(start, 6)}
  end
end
