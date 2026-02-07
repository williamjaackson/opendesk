class AddUniqueIndexToNotifications < ActiveRecord::Migration[8.1]
  def change
    remove_index :notifications, name: "index_notifications_on_notifiable"
    add_index :notifications, [ :user_id, :notifiable_type, :notifiable_id ],
              unique: true,
              name: "index_notifications_on_user_and_notifiable"
  end
end
