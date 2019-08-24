# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DtCtx.Repo.insert!(%SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias DtCtx.Accounts.User

admin_user = %User{
  name: "admin",
  username: "admin@local",
  password: Bcrypt.hash_pwd_salt("password"),
  role: "admin",
  pin: "666666"
}

DtCtx.Repo.insert!(admin_user)
