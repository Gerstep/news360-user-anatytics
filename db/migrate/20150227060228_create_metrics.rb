class CreateMetrics < ActiveRecord::Migration
  def change
    create_table :metrics do |t|
      t.string :app
      t.string :name
      t.datetime :date
      t.integer :value

      t.timestamps
    end
  end
end
