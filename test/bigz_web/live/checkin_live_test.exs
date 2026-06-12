defmodule BigzWeb.CheckinLiveTest do
  use BigzWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Bigz.AccountsFixtures

  alias Bigz.Habits
  alias Bigz.Habits.Checkin
  alias Bigz.Accounts.Scope

  defp create_habit(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Eco-habit",
        description: "A sustainable habit",
        category: "água",
        points: 20
      })

    {:ok, habit} = Habits.create_habit(Scope.for_user(user), attrs)
    habit
  end

  describe "Unauthenticated access" do
    test "redirects to login when visiting check-in page without authentication", %{conn: conn} do
      user = user_fixture()
      habit = create_habit(user)

      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/habits/#{habit.id}/checkin")
    end
  end

  describe "Authenticated check-in" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      habit = create_habit(user)
      %{conn: conn, user: user, habit: habit}
    end

    test "renders the check-in confirmation page with habit details", %{
      conn: conn,
      habit: habit
    } do
      {:ok, _view, html} = live(conn, ~p"/habits/#{habit.id}/checkin")

      assert html =~ "Registrar Check-in"
      assert html =~ habit.name
      assert html =~ "#{habit.points} pontos"
    end

    test "successful check-in shows flash message and redirects to habits list", %{
      conn: conn,
      habit: habit
    } do
      {:ok, view, _html} = live(conn, ~p"/habits/#{habit.id}/checkin")

      {:ok, _view, html} =
        view
        |> render_click("checkin", %{})
        |> follow_redirect(conn, ~p"/habits")

      assert html =~ "Check-in registrado!"
      assert html =~ "#{habit.points} pontos acumulados"
    end

    test "duplicate check-in on the same day shows friendly error message", %{
      conn: conn,
      user: user,
      habit: habit
    } do
      Habits.create_checkin(Scope.for_user(user), habit)

      {:ok, view, _html} = live(conn, ~p"/habits/#{habit.id}/checkin")

      html = render_click(view, "checkin", %{})

      assert html =~ "Você já registrou este hábito hoje."
    end

    test "user_id injected via event params is ignored — check-in always belongs to authenticated user",
         %{conn: conn, user: user, habit: habit} do
      other_user = user_fixture(%{email: "attacker@example.com"})

      {:ok, view, _html} = live(conn, ~p"/habits/#{habit.id}/checkin")

      render_click(view, "checkin", %{"user_id" => other_user.id})

      assert Bigz.Repo.get_by(Checkin, user_id: user.id, habit_id: habit.id)
      refute Bigz.Repo.get_by(Checkin, user_id: other_user.id, habit_id: habit.id)
    end
  end
end
