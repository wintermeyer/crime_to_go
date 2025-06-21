defmodule CrimeToGo.Repo.Migrations.AddPreparingStateToGames do
  use Ecto.Migration

  def change do
    # Note: This migration doesn't need to alter the database schema
    # as the state field already exists. The new 'preparing' state
    # is now valid through the application logic (Constants module).
    # This migration serves as documentation of when this state was added.
  end
end