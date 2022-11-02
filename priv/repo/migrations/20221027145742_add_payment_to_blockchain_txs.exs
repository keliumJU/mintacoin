defmodule Mintacoin.Repo.Migrations.AddPaymentToBlockchainTxs do
  use Ecto.Migration

  def change do
    alter table(:blockchain_txs) do
      add(:payment_id, references(:payments, type: :uuid), null: true)
    end
  end
end
