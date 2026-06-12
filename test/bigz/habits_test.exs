defmodule Bigz.HabitsTest do
  use Bigz.DataCase

  alias Bigz.Habits
  alias Bigz.Habits.Habit
  alias Bigz.Accounts.Scope

  import Bigz.AccountsFixtures

  def habit_fixture(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Test Habit",
        description: "This is a test description",
        category: "transporte",
        points: 10
      })

    {:ok, habit} = Habits.create_habit(Scope.for_user(user), attrs)
    habit
  end

  describe "habits context" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "list_habits/2 returns all habits", %{scope: scope, user: user} do
      habit = habit_fixture(user)
      assert [retrieved] = Habits.list_habits(scope)
      assert retrieved.id == habit.id
      assert retrieved.user.id == user.id
    end

    test "list_habits/2 filters by category", %{scope: scope, user: user} do
      habit1 = habit_fixture(user, %{name: "Habit 1", category: "transporte"})
      _habit2 = habit_fixture(user, %{name: "Habit 2", category: "energia"})

      assert [retrieved] = Habits.list_habits(scope, %{"category" => "transporte"})
      assert retrieved.id == habit1.id

      assert [] = Habits.list_habits(scope, %{"category" => "água"})
    end

    test "get_habit!/2 returns the habit with given id", %{scope: scope, user: user} do
      habit = habit_fixture(user)
      assert retrieved = Habits.get_habit!(scope, habit.id)
      assert retrieved.id == habit.id
    end

    test "create_habit/2 with valid data creates a habit", %{scope: scope, user: user} do
      valid_attrs = %{
        name: "Eco-driving",
        description: "Driving slowly",
        category: "transporte",
        points: 20
      }

      assert {:ok, %Habit{} = habit} = Habits.create_habit(scope, valid_attrs)
      assert habit.name == "Eco-driving"
      assert habit.description == "Driving slowly"
      assert habit.category == "transporte"
      assert habit.points == 20
      assert habit.user_id == user.id
    end

    test "create_habit/2 with invalid data returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Habits.create_habit(scope, %{points: -10})
    end

    test "update_habit/3 updates the habit if owned", %{scope: scope, user: user} do
      habit = habit_fixture(user)

      assert {:ok, %Habit{} = updated} =
               Habits.update_habit(scope, habit, %{name: "Updated Name"})

      assert updated.name == "Updated Name"
    end

    test "update_habit/3 returns error if not owned", %{user: user} do
      habit = habit_fixture(user)
      other_user = user_fixture(%{email: "other@example.com"})
      other_scope = Scope.for_user(other_user)

      assert {:error, :unauthorized} =
               Habits.update_habit(other_scope, habit, %{name: "Updated Name"})
    end

    test "delete_habit/2 deletes the habit if owned", %{scope: scope, user: user} do
      habit = habit_fixture(user)
      assert {:ok, %Habit{}} = Habits.delete_habit(scope, habit)
      assert_raise Ecto.NoResultsError, fn -> Habits.get_habit!(scope, habit.id) end
    end

    test "delete_habit/2 returns error if not owned", %{user: user} do
      habit = habit_fixture(user)
      other_user = user_fixture(%{email: "other@example.com"})
      other_scope = Scope.for_user(other_user)

      assert {:error, :unauthorized} = Habits.delete_habit(other_scope, habit)
    end

    test "change_habit/3 returns a habit changeset", %{scope: scope, user: user} do
      habit = habit_fixture(user)
      assert %Ecto.Changeset{} = Habits.change_habit(scope, habit)
    end
  end
end
