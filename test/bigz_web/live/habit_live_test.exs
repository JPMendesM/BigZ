defmodule BigzWeb.HabitLiveTest do
  use BigzWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bigz.AccountsFixtures
  alias Bigz.Habits

  defp create_habit(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Eco-driving habit",
        description: "Reduce speed",
        category: "transporte",
        points: 15
      })

    {:ok, habit} = Habits.create_habit(Bigz.Accounts.Scope.for_user(user), attrs)
    habit
  end

  describe "Index (Guest Access)" do
    setup %{conn: conn} do
      user = user_fixture()
      habit = create_habit(user)
      %{conn: conn, user: user, habit: habit}
    end

    test "lists habits and hides creation/management buttons for guest", %{
      conn: conn,
      habit: habit
    } do
      {:ok, view, html} = live(conn, ~p"/habits")

      assert html =~ "Hábitos Sustentáveis"
      assert has_element?(view, "#habits-#{habit.id}")
      refute has_element?(view, "#habits-#{habit.id} a[href*='/edit']")
      refute has_element?(view, "#habits-#{habit.id} a[phx-click*='delete']")
      # "Cadastrar Hábito" button should be disabled for guest
      assert has_element?(view, ".btn-disabled", "Cadastrar Hábito")
    end

    test "redirects to login when trying to access new habit page as guest", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/habits/new")
    end
  end

  describe "Index (Authenticated User Access)" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "shows active Cadastrar Hábito link and allows own habit management", %{
      conn: conn,
      user: user
    } do
      own_habit = create_habit(user, %{name: "My custom habit"})
      other_user = user_fixture(%{email: "other_user@example.com"})
      other_habit = create_habit(other_user, %{name: "Other user habit"})

      {:ok, view, _html} = live(conn, ~p"/habits")

      # Cadastrar Hábito button should be active (not disabled)
      assert has_element?(view, "a", "Cadastrar Hábito")
      refute has_element?(view, "a.btn-disabled", "Cadastrar Hábito")

      # Own habit should have edit/delete controls
      assert has_element?(view, "#habits-#{own_habit.id}")
      assert has_element?(view, "#habits-#{own_habit.id} a[href='/habits/#{own_habit.id}/edit']")
      assert has_element?(view, "#habits-#{own_habit.id} a[phx-click*='delete']")

      # Other habit should not have edit/delete controls
      assert has_element?(view, "#habits-#{other_habit.id}")

      refute has_element?(
               view,
               "#habits-#{other_habit.id} a[href='/habits/#{other_habit.id}/edit']"
             )

      refute has_element?(view, "#habits-#{other_habit.id} a[phx-click*='delete']")
    end

    test "saves new habit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/habits/new")

      assert has_element?(view, "h2", "Novo Hábito")

      # Submit invalid data
      assert view
             |> form("form", habit: %{name: "", points: -5})
             |> render_change() =~ "can&#39;t be blank"

      # Submit valid data
      {:ok, _view, html} =
        view
        |> form("form",
          habit: %{
            name: "Recycle paper",
            description: "Recycle office paper",
            category: "resíduos",
            points: 25
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/habits")

      assert html =~ "Hábito cadastrado com sucesso!"
      assert html =~ "Recycle paper"
    end

    test "updates own habit", %{conn: conn, user: user} do
      habit = create_habit(user, %{name: "Old Habit Name"})

      {:ok, view, _html} = live(conn, ~p"/habits/#{habit.id}/edit")

      assert has_element?(view, "h2", "Editar Hábito")

      {:ok, _view, html} =
        view
        |> form("form", habit: %{name: "New Habit Name"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/habits")

      assert html =~ "Hábito atualizado com sucesso!"
      assert html =~ "New Habit Name"
    end

    test "fails to edit other user's habit", %{conn: conn} do
      other_user = user_fixture(%{email: "other@example.com"})
      other_habit = create_habit(other_user, %{name: "Other Habit"})

      # Trying to visit edit page directly redirects
      assert {:error,
              {:live_redirect,
               %{
                 to: "/habits",
                 flash: %{"error" => "Você não tem permissão para editar este hábito."}
               }}} =
               live(conn, ~p"/habits/#{other_habit.id}/edit")
    end

    test "deletes own habit", %{conn: conn, user: user} do
      habit = create_habit(user, %{name: "Delete Me"})

      {:ok, view, _html} = live(conn, ~p"/habits")

      assert has_element?(view, "#habits-#{habit.id}")

      # Trigger deletion
      render_click(element(view, "#habits-#{habit.id} a[phx-click*='delete']"))

      refute has_element?(view, "#habits-#{habit.id}")
    end
  end
end
