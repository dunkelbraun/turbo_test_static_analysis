# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191005094551) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "some_extension"

  create_table "admins", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "user_type_id"
    t.string   "user_name"
    t.string   "password"
    t.datetime "last_login_date"
    t.string   "title"
  end

  add_index "profiles", ["confirmed"], name: "index_profiles_on_confirmed", using: :btree
  add_index "profiles", ["email"], name: "index_profiles_on_email", using: :btree
  add_index "profiles", ["user_id"], name: "index_profiles_on_user_id", using: :btree
  add_index "profiles", ["title"], name: "index_profiles_on_title", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider",                               null: false
    t.string   "uid",                    default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "username",                               null: false
    t.string   "email",                                  null: false
    t.text     "tokens"
    t.text     "more_tokens"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "banned",                 default: false, null: false
    t.datetime "last_unblock_date"
  end

  add_index "users", ["banned"], name: "index_users_on_banned", using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  add_foreign_key "profiles", "users"
  
  create_trigger("fm_after_insert_row_tr", :generated => true, :compatibility => 1).
      on("users").
      after(:insert) do
    <<-SQL_ACTIONS
    thisTrigger: BEGIN
      SOME SQL CODE
    SQL_ACTIONS
  end
  
  do_something_else "users", force: :cascade do |t|
    t.string "provider", null: false
  end

  def hello
    if :a == :b
      g = 1
      t = 2
      4.times do |z,t|
        next
      end
    end
  end
end


def house
  if :a == :b
    g = 1
    t = 2
    4.times do |z,t|
      next
    end
  end
end

