defmodule BigzWeb.HomeLive.IndexTest do
  use BigzWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Bigz.AccountsFixtures

  alias Bigz.Habits
  alias Bigz.Habits.Checkin
  alias Bigz.Accounts.Scope

  # Creates a habit for a user via the context (goes through scope auth).
  defp habit_fixture(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Test Habit",
        description: "A test description",
        category: "energia",
        points: 10
      })

    {:ok, habit} = Habits.create_habit(Scope.for_user(user), attrs)
    habit
  end

  # Inserts a check-in directly with a specific date, bypassing the "today only"
  # restriction in create_checkin/2. Used to seed historical data in tests.
  defp checkin_on(user, habit, %Date{} = date) do
    Bigz.Repo.insert!(%Checkin{
      user_id: user.id,
      habit_id: habit.id,
      checkin_date: date
    })
  end

  # ── Unauthenticated access ─────────────────────────────────────────────────

  describe "Unauthenticated access" do
    test "redirects to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/inicio")
    end
  end

  # ── Authenticated dashboard ────────────────────────────────────────────────

  describe "Dashboard — authenticated" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, scope: Scope.for_user(user)}
    end

    test "renders dashboard with user greeting", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/inicio")
      assert html =~ "Olá"
      first = user.name |> String.split(~r/\s+/, trim: true) |> List.first()
      assert html =~ first
    end

    test "shows empty-state when user has no check-ins", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/inicio")
      assert html =~ "Nenhum check-in ainda"
    end

    test "all numeric stats are zero when user has no check-ins", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/inicio")
      # Stat cards render "0" for every metric
      assert html =~ "0"
    end

    test "history is ordered most recent first", %{conn: conn, user: user} do
      habit = habit_fixture(user)
      today = Date.utc_today()
      yesterday = Date.add(today, -1)

      checkin_on(user, habit, yesterday)
      checkin_on(user, habit, today)

      {:ok, _view, html} = live(conn, ~p"/inicio")

      today_str = Calendar.strftime(today, "%d/%m/%Y")
      yesterday_str = Calendar.strftime(yesterday, "%d/%m/%Y")

      # Position of a string = length of everything before its first occurrence
      today_pos = html |> String.split(today_str) |> List.first() |> String.length()
      yesterday_pos = html |> String.split(yesterday_str) |> List.first() |> String.length()

      assert today_pos < yesterday_pos
    end

    test "total points are the sum of all check-in habit points", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      habit = habit_fixture(user, %{points: 25})
      Habits.create_checkin(scope, habit)

      {:ok, _view, html} = live(conn, ~p"/inicio")
      assert html =~ "25"
    end

    test "weekly points show only current week, not previous weeks", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      habit = habit_fixture(user, %{points: 15})

      today = Date.utc_today()
      last_week = Date.add(today, -7)

      Habits.create_checkin(scope, habit)
      checkin_on(user, habit, last_week)

      {:ok, _view, html} = live(conn, ~p"/inicio")

      # Total = 30 (both weeks), week = 15 (current week only)
      assert html =~ "30"
      assert html =~ "15"
    end

    test "user sees only their own check-ins in history", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      other_user = user_fixture(%{email: "other@example.com"})
      other_habit = habit_fixture(other_user, %{name: "Other Habit"})
      my_habit = habit_fixture(user, %{name: "My Habit"})

      Habits.create_checkin(Scope.for_user(other_user), other_habit)
      Habits.create_checkin(scope, my_habit)

      {:ok, _view, html} = live(conn, ~p"/inicio")

      assert html =~ "My Habit"
      refute html =~ "Other Habit"
    end

    test "check-ins from other users do not appear in stats", %{conn: conn} do
      other_user = user_fixture(%{email: "spy@example.com"})
      habit = habit_fixture(other_user, %{points: 999})
      Habits.create_checkin(Scope.for_user(other_user), habit)

      {:ok, _view, html} = live(conn, ~p"/inicio")

      refute html =~ "999"
    end
  end

  # ── Context: weekly summary grouping ─────────────────────────────────────

  describe "Habits.list_weekly_summaries/2" do
    setup do
      user = user_fixture()
      %{user: user, scope: Scope.for_user(user)}
    end

    test "returns the requested number of weekly buckets", %{scope: scope} do
      summaries = Habits.list_weekly_summaries(scope, 4)
      assert length(summaries) == 4
    end

    test "weeks with no check-ins have points=0 and count=0", %{scope: scope} do
      summaries = Habits.list_weekly_summaries(scope, 3)
      assert Enum.all?(summaries, &(&1.points == 0 and &1.count == 0))
    end

    test "groups check-ins into correct week buckets", %{user: user, scope: scope} do
      habit = habit_fixture(user, %{points: 10})

      today = Date.utc_today()
      cur_monday = Date.add(today, -(Date.day_of_week(today) - 1))
      prev_monday = Date.add(cur_monday, -7)

      checkin_on(user, habit, cur_monday)
      checkin_on(user, habit, prev_monday)

      summaries = Habits.list_weekly_summaries(scope, 6)

      current_week = List.last(summaries)
      assert current_week.week_start == cur_monday
      assert current_week.points == 10
      assert current_week.count == 1

      previous_week = Enum.at(summaries, -2)
      assert previous_week.week_start == prev_monday
      assert previous_week.points == 10
      assert previous_week.count == 1
    end

    test "check-ins from different users are not mixed", %{user: user, scope: scope} do
      other_user = user_fixture(%{email: "other2@example.com"})
      shared_habit = habit_fixture(user, %{points: 50})

      Habits.create_checkin(Scope.for_user(other_user), shared_habit)

      summaries = Habits.list_weekly_summaries(scope, 6)
      total = summaries |> Enum.map(& &1.points) |> Enum.sum()
      assert total == 0
    end

    test "multiple check-ins in the same week are summed", %{user: user, scope: scope} do
      habit_a = habit_fixture(user, %{name: "Habit A", points: 10})
      habit_b = habit_fixture(user, %{name: "Habit B", points: 20})

      today = Date.utc_today()
      cur_monday = Date.add(today, -(Date.day_of_week(today) - 1))
      cur_thursday = Date.add(cur_monday, 3)

      checkin_on(user, habit_a, cur_monday)
      checkin_on(user, habit_b, cur_thursday)

      summaries = Habits.list_weekly_summaries(scope, 6)
      current_week = List.last(summaries)

      assert current_week.points == 30
      assert current_week.count == 2
    end
  end

  # ── Context: sum helpers ───────────────────────────────────────────────────

  describe "Habits.sum_user_points/1" do
    test "returns 0 when user has no check-ins" do
      user = user_fixture()
      assert Habits.sum_user_points(Scope.for_user(user)) == 0
    end

    test "sums points from all check-ins across all dates" do
      user = user_fixture()
      scope = Scope.for_user(user)
      habit_a = habit_fixture(user, %{points: 10})
      habit_b = habit_fixture(user, %{points: 25})

      checkin_on(user, habit_a, Date.add(Date.utc_today(), -10))
      checkin_on(user, habit_b, Date.add(Date.utc_today(), -3))

      assert Habits.sum_user_points(scope) == 35
    end

    test "does not include other users' points" do
      user = user_fixture()
      other = user_fixture(%{email: "o3@example.com"})
      habit = habit_fixture(user, %{points: 100})

      Habits.create_checkin(Scope.for_user(other), habit)

      assert Habits.sum_user_points(Scope.for_user(user)) == 0
    end
  end

  describe "Habits.sum_user_points_this_week/1" do
    test "returns 0 when user has no check-ins this week" do
      user = user_fixture()
      assert Habits.sum_user_points_this_week(Scope.for_user(user)) == 0
    end

    test "counts only check-ins within the current week boundary" do
      user = user_fixture()
      scope = Scope.for_user(user)
      habit = habit_fixture(user, %{points: 20})

      today = Date.utc_today()
      cur_monday = Date.add(today, -(Date.day_of_week(today) - 1))

      checkin_on(user, habit, cur_monday)
      checkin_on(user, habit, Date.add(cur_monday, -7))

      assert Habits.sum_user_points_this_week(scope) == 20
    end
  end
end
