defmodule BigzWeb.CommunityLive.IndexTest do
  # async: false because Phoenix.PubSub.broadcast/3 sends to all subscribers
  # on the topic across the test suite. Running async would let broadcasts
  # from one test leak into another test's LiveView process.
  use BigzWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Bigz.AccountsFixtures

  alias Bigz.Habits
  alias Bigz.Habits.Checkin
  alias Bigz.Accounts.Scope

  defp habit_fixture(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Community Habit",
        description: "A test habit",
        category: "energia",
        points: 10
      })

    {:ok, habit} = Habits.create_habit(Scope.for_user(user), attrs)
    habit
  end

  # Inserts a checkin directly (bypasses today-only rule) and preloads
  # user + habit so it can be used as a broadcast payload.
  defp checkin_fixture(user, habit, date \\ nil) do
    date = date || Date.utc_today()

    checkin =
      Bigz.Repo.insert!(%Checkin{
        user_id: user.id,
        habit_id: habit.id,
        checkin_date: date
      })

    Bigz.Repo.preload(checkin, [:user, :habit])
  end

  # ── Unauthenticated access ─────────────────────────────────────────────────

  describe "Unauthenticated access" do
    test "redirects to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/comunidade")
    end
  end

  # ── Authenticated feed ─────────────────────────────────────────────────────

  describe "Community feed — authenticated" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, scope: Scope.for_user(user)}
    end

    test "renders feed with title and live indicator", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/comunidade")
      assert html =~ "Comunidade"
      assert html =~ "Ao vivo"
    end

    test "shows empty state when no check-ins exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/comunidade")
      assert html =~ "Nenhuma atividade ainda"
    end

    test "shows check-ins from all users including others", %{conn: conn, user: user} do
      other = user_fixture(%{email: "other@example.com"})
      my_habit = habit_fixture(user, %{name: "My Habit"})
      their_habit = habit_fixture(other, %{name: "Their Habit"})

      checkin_fixture(user, my_habit)
      checkin_fixture(other, their_habit)

      {:ok, _view, html} = live(conn, ~p"/comunidade")

      assert html =~ "My Habit"
      assert html =~ "Their Habit"
    end

    test "displays user name and habit name", %{conn: conn, user: user} do
      habit = habit_fixture(user, %{name: "Solar Panel Habit"})
      checkin_fixture(user, habit)

      {:ok, _view, html} = live(conn, ~p"/comunidade")

      assert html =~ user.name
      assert html =~ "Solar Panel Habit"
    end

    test "never renders email or password-related fields", %{conn: conn, user: user} do
      habit = habit_fixture(user)
      checkin_fixture(user, habit)

      {:ok, _view, html} = live(conn, ~p"/comunidade")

      refute html =~ user.email
      refute html =~ "hashed_password"
      refute html =~ "password"
    end

    test "check-ins are ordered most recent first", %{conn: conn, user: user} do
      habit_a = habit_fixture(user, %{name: "Older Habit"})
      habit_b = habit_fixture(user, %{name: "Newer Habit"})

      checkin_fixture(user, habit_a, Date.add(Date.utc_today(), -1))
      checkin_fixture(user, habit_b, Date.utc_today())

      {:ok, _view, html} = live(conn, ~p"/comunidade")

      newer_pos = html |> String.split("Newer Habit") |> List.first() |> String.length()
      older_pos = html |> String.split("Older Habit") |> List.first() |> String.length()

      assert newer_pos < older_pos
    end

    test "user and habit are preloaded (no association error)", %{conn: conn, user: user} do
      habit = habit_fixture(user)
      checkin_fixture(user, habit)

      # If preload is missing, rendering would crash with an association not loaded error
      {:ok, _view, html} = live(conn, ~p"/comunidade")
      assert html =~ habit.name
      assert html =~ user.name
    end
  end

  # ── PubSub — real-time behavior ────────────────────────────────────────────

  describe "PubSub integration" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, scope: Scope.for_user(user)}
    end

    test "subscribes to community topic on connect and receives new check-ins via handle_info",
         %{conn: conn, user: user} do
      habit = habit_fixture(user, %{name: "Real-Time Habit"})
      {:ok, view, _html} = live(conn, ~p"/comunidade")

      checkin = checkin_fixture(user, habit)

      # Simulate a PubSub broadcast by sending directly to the LiveView process
      send(view.pid, {:new_checkin, checkin})

      assert render(view) =~ "Real-Time Habit"
    end

    test "new check-in appears at the top of the feed", %{conn: conn, user: user} do
      old_habit = habit_fixture(user, %{name: "Old Habit"})
      checkin_fixture(user, old_habit, Date.add(Date.utc_today(), -2))

      {:ok, view, _html} = live(conn, ~p"/comunidade")

      new_habit = habit_fixture(user, %{name: "Brand New Habit"})
      new_checkin = checkin_fixture(user, new_habit)

      send(view.pid, {:new_checkin, new_checkin})

      html = render(view)
      new_pos = html |> String.split("Brand New Habit") |> List.first() |> String.length()
      old_pos = html |> String.split("Old Habit") |> List.first() |> String.length()

      assert new_pos < old_pos
    end

    test "same check-in sent twice does not appear twice in the feed", %{
      conn: conn,
      user: user
    } do
      habit = habit_fixture(user, %{name: "Unique Habit XYZ"})
      {:ok, view, _html} = live(conn, ~p"/comunidade")

      checkin = checkin_fixture(user, habit)

      send(view.pid, {:new_checkin, checkin})
      send(view.pid, {:new_checkin, checkin})

      html = render(view)

      # Count occurrences of the unique habit name in the rendered HTML
      occurrences = html |> String.split("Unique Habit XYZ") |> length() |> Kernel.-(1)
      assert occurrences == 1
    end

    test "full broadcast flow: create_checkin triggers update in connected LiveView", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      habit = habit_fixture(user, %{name: "Broadcast Habit"})
      {:ok, view, _html} = live(conn, ~p"/comunidade")

      # create_checkin broadcasts after insert; the LiveView receives it via handle_info
      {:ok, _checkin} = Habits.create_checkin(scope, habit)

      assert render(view) =~ "Broadcast Habit"
    end

    test "broadcast from another user appears in the feed", %{conn: conn, user: user} do
      other = user_fixture(%{email: "broadcaster@example.com"})
      habit = habit_fixture(other, %{name: "Other User Habit"})

      {:ok, view, _html} = live(conn, ~p"/comunidade")

      checkin = checkin_fixture(other, habit)
      send(view.pid, {:new_checkin, checkin})

      assert render(view) =~ "Other User Habit"
    end

    test "broadcast payload never renders sensitive fields", %{conn: conn, user: user} do
      habit = habit_fixture(user)
      {:ok, view, _html} = live(conn, ~p"/comunidade")

      checkin = checkin_fixture(user, habit)
      send(view.pid, {:new_checkin, checkin})

      html = render(view)
      refute html =~ user.email
      refute html =~ "hashed_password"
    end
  end
end
