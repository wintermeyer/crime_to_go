defmodule CrimeToGo.Repo.Migrations.AddKickedStatusToPlayers do
  use Ecto.Migration

  def change do
    # Update the check constraint to allow "kicked" status
    execute(
      "ALTER TABLE players DROP CONSTRAINT IF EXISTS players_status_check",
      "ALTER TABLE players ADD CONSTRAINT players_status_check CHECK (status IN ('online', 'offline'))"
    )
    
    execute(
      "ALTER TABLE players ADD CONSTRAINT players_status_check CHECK (status IN ('online', 'offline', 'kicked'))",
      "ALTER TABLE players DROP CONSTRAINT players_status_check"
    )
  end
end
