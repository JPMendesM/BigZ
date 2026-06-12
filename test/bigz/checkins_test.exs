defmodule Bigz.CheckinsTest do
  use Bigz.DataCase, async: true

  alias Bigz.Habits
  alias Bigz.Habits.Checkin
  alias Bigz.Accounts.Scope

  import Bigz.AccountsFixtures

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

  describe "create_checkin/2" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)
      habit = habit_fixture(user)
      %{user: user, scope: scope, habit: habit}
    end

    test "creates a valid check-in with server-assigned date and correct user", %{
      scope: scope,
      habit: habit,
      user: user
    } do
      assert {:ok, %Checkin{} = checkin} = Habits.create_checkin(scope, habit)
      assert checkin.user_id == user.id
      assert checkin.habit_id == habit.id
      assert checkin.checkin_date == Date.utc_today()
    end

    test "returns error changeset on duplicate (same user, habit, and day)", %{
      scope: scope,
      habit: habit
    } do
      assert {:ok, _} = Habits.create_checkin(scope, habit)
      assert {:error, %Ecto.Changeset{} = changeset} = Habits.create_checkin(scope, habit)
      assert "Você já registrou este hábito hoje." in errors_on(changeset).user_id
    end

    test "allows two different users to check in on the same habit on the same day", %{
      habit: habit
    } do
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})

      assert {:ok, _} = Habits.create_checkin(Scope.for_user(user1), habit)
      assert {:ok, _} = Habits.create_checkin(Scope.for_user(user2), habit)
    end

    test "allows the same user to check in on different habits on the same day", %{
      scope: scope,
      user: user
    } do
      habit1 = habit_fixture(user, %{name: "Habit One"})
      habit2 = habit_fixture(user, %{name: "Habit Two"})

      assert {:ok, _} = Habits.create_checkin(scope, habit1)
      assert {:ok, _} = Habits.create_checkin(scope, habit2)
    end
  end
end
