# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_191_005_094_551) do
  create_table "admins", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "user_type_id"
    t.string   "user_name"
    t.string   "password"
    t.string   "title"
  end

  add_index "admins", ["confirmed"], name: "index_profiles_on_confirmed", using: :btree
  add_index "admins", ["email"], name: "index_profiles_on_email", using: :btree
  add_index "admins", ["user_id"], name: "index_profiles_on_user_id", using: :btree
  add_index "admins", ["title"], name: "index_profiles_on_title", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider",                               null: false
    t.string   "uid",                    default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "username", null: false
    t.text     "tokens"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "banned", default: false, null: false
    t.datetime "last_unblock_date"
  end

  add_index "users", ["banned"], name: "index_users_on_banned", using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", %w[uid provider], name: "index_users_on_uid_and_provider", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree
end
