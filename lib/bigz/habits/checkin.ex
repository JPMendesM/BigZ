defmodule Bigz.Habits.Checkin do
  use Ecto.Schema
  import Ecto.Changeset

  schema "checkins" do
    # checkin_date is always set server-side via Date.utc_today/0.
    # The "same day" rule is evaluated in UTC regardless of the user's local timezone.
    field :checkin_date, :date

    belongs_to :user, Bigz.Accounts.User
    belongs_to :habit, Bigz.Habits.Habit

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for inserting a new check-in.

  All fields (user_id, habit_id, checkin_date) are set on the struct before
  this changeset is called; cast/2 accepts no user-supplied attributes.
  """
  def changeset(checkin, attrs) do
    checkin
    |> cast(attrs, [])
    |> validate_required([:user_id, :habit_id, :checkin_date])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:habit_id)
    |> unique_constraint([:user_id, :habit_id, :checkin_date],
      name: :checkins_user_id_habit_id_checkin_date_index,
      message: "Você já registrou este hábito hoje."
    )
  end
end
